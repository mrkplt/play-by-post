# Deploying play-by-post to PiHost (Coolify)

Target: **PiHost** — Raspberry Pi 4, 8GB, aarch64, Debian 13, at `10.0.0.233`.
Coolify dashboard: `http://10.0.0.233:8000` (LAN only, plain HTTP).

Model: **build off-device, pull on the Pi.** Images are built by GitHub Actions and
pulled from GHCR. Do not build on the Pi — its USB-SATA bridge runs without command
queuing, so builds are slow and IO-heavy.

---

## Stack

Two containers. **No Redis and no database server** — the app runs on SQLite.

    web        ghcr.io/mrkplt/play-by-post   Thruster + Puma on :80
    worker     same image                    bundle exec rake solid_queue:start

The database files live on the named volume `dbdata`, mounted at `/data` in **both**
containers, so web and worker stay separate processes sharing one database. Rails 8
runs SQLite in WAL mode, which allows readers to proceed during a write and makes
that sharing safe.

`config/database.yml` defines **three production databases** — primary, `_cache` and
`_queue` — each its own file under `/data`, each with its own migration path.
`bin/docker-entrypoint` runs `db:prepare` when the server starts, which creates and
migrates all three. The worker does not run migrations, which is correct: only one
process should. The worker waits on web's healthcheck, because with Postgres gone
web is the only thing that creates the database.

---

## 1. Build the image

`.github/workflows/build-image.yml` builds on push to `master`, on `v*` tags, or manually
via workflow_dispatch.

It uses **`ubuntu-24.04-arm`** runners — native arm64, no QEMU emulation. These are free
for public repositories, which this one is.

**arm64 is mandatory.** The Pi is aarch64; an amd64-only image will not run.

Verify after any build:

    docker image inspect ghcr.io/mrkplt/play-by-post:<tag> --format '{{.Architecture}}'
    # must print: arm64

Tags produced: `sha-<full-sha>`, the branch name, `latest` on the default branch, and
semver tags for `v*` releases.

---

## 2. Give Coolify pull access to GHCR

The package inherits the repository's visibility. If the package is public, no credentials
are needed. If it is private:

1. Create a GitHub PAT with **`read:packages`** scope only.
2. Coolify -> **Settings -> Docker Registries** -> add `ghcr.io`, your username, the PAT.

Verify on the Pi:

    docker pull ghcr.io/mrkplt/play-by-post:<tag>

---

## 3. Deploy

Coolify -> **Project -> + Add Resource -> Docker Compose Empty**, then paste the contents
of `docker-compose.yml`.

Both services set **`pull_policy: always`**. Without it, Coolify redeploys the cached
`:latest` layer instead of pulling the new digest from GHCR, so a "successful" deploy can
silently run stale code (ref: coollabsio/coolify discussion #7498).

Set the environment variables in the Coolify UI — never commit them.

**The complete, authoritative list is [docs/CONFIGURATION.md](docs/CONFIGURATION.md).** It
covers required and optional variables, the values that must go in encrypted credentials
instead, and the variables that must *not* be set in production. It is deliberately not
duplicated here.

Two things that bite during this step, both detailed in that file:

- The container has **no credentials key baked in**, so Resend and OpenRouter features fail
  at runtime unless the key is supplied — even though the app boots and serves pages fine.
- The `worker` service needs the same storage, LLM and host variables as `web`, because
  scene summaries and Active Storage processing run as background jobs.

---

## 4. Verify

    docker compose -p <service> ps
    # web and worker both Up; web healthy

    docker compose -p <service> logs --tail 50 web
    # look for db:prepare completing and Puma booting

    docker compose -p <service> logs --tail 50 worker
    # SolidQueue::Supervisor started

    docker compose -p <service> exec web ls -la /data
    # production.sqlite3, production_cache.sqlite3, production_queue.sqlite3
    # each with -wal and -shm sidecars once written to

    docker compose -p <service> exec web \
      sqlite3 /data/production.sqlite3 'pragma journal_mode;'
    # wal

The web container has a healthcheck against `/up` (`rails/health#show`, confirmed present
in `config/routes.rb`). `curl` is installed in the image's base stage, so the check works.

---

## 5. Routing

Assign a domain/host in the Coolify UI for the `web` service. Traefik routes to it by
hostname on ports 80/443.

**Let's Encrypt HTTP-01 cannot validate against a private address** (10.0.0.233) — the CA
cannot reach the host from the internet. Options:

- **LAN-only over HTTP** — simplest, fits the current posture.
- **DNS-01 challenge** against a domain you control — real certificates, no inbound ports.
- **Tunnel** (e.g. Cloudflare Tunnel) if the app genuinely needs public reachability.

---

## 6. Automatic deploys of master

After the image is built and pushed, `build-image.yml` triggers a redeploy automatically —
no manual step per merge. The chain:

    merge to master
      -> build-image.yml builds + pushes image to GHCR
      -> workflow POSTs to https://<app-host>/webhooks/deploy  (Authorization: Bearer <secret>)
      -> Webhooks::DeployController verifies the secret, enqueues CoolifyDeployJob (202)
      -> CoolifyDeployJob GETs Coolify's API deploy URL over the internal network
      -> Coolify pulls the fresh image (pull_policy: always) and swaps containers

**Why the relay exists:** Coolify's API is not exposed to the internet, so GitHub cannot call
it directly. The app *is* internet-facing and can reach Coolify internally, so it relays the
trigger. Source: `app/controllers/webhooks/deploy_controller.rb`, `app/jobs/coolify_deploy_job.rb`.

**Required configuration** (all in [docs/CONFIGURATION.md](docs/CONFIGURATION.md)):

- GitHub Actions secrets: `DEPLOY_WEBHOOK_URL` (the `/webhooks/deploy` URL) and
  `DEPLOY_WEBHOOK_SECRET`.
- Rails credentials: `deploy_webhook_secret` (must equal the GitHub secret, byte-for-byte),
  and `coolify.deploy_url` / `coolify.token`.

**Gotchas learned in setup:**

- The shared secret lives in two systems (GitHub secret + Rails credential) and must match
  exactly. A trailing newline (from `echo` instead of `printf %s`) causes a silent 401. The
  workflow's `Trigger deploy` step returning 401 means secret mismatch; 404 means the running
  app predates the relay route (stale image — see `pull_policy` above).
- Coolify's **API allowlist matches the proxy's source IP, not the caller's.** Scope
  "Allowed IPs for API Access" to the coolify-proxy subnets (`172.20.0.0/16`), not the
  worker container's own `/24`, or every call 403s with "You are not allowed to access the API".
- Changing `deploy_webhook_secret` requires a redeploy to take effect (credentials are read at
  boot), and that first redeploy must be triggered manually — the deploy that ships the new
  secret can't be triggered by it.

---

## 7. Error tracking (GlitchTip)

Unhandled exceptions report to a self-hosted **GlitchTip** instance (Sentry-protocol
compatible) via the `sentry-ruby` / `sentry-rails` SDKs. Initialization is DSN-gated in
`config/initializers/sentry.rb`: it only runs when `glitchtip.dsn` (credentials) or
`GLITCHTIP_DSN` (env fallback) is set, so local dev and CI report nothing.

Verify it initialized in the running container:

    docker compose -p <service> exec web \
      sh -c 'RAILS_ENV=production bin/rails runner "puts Sentry.initialized?"'
    # true = SDK live and reporting to the configured DSN

---

## Resource budget

Memory limits total ~1.75GB of the Pi's 8GB, leaving room for Coolify (~0.8GB) and headroom:

    web        1g
    worker     768m

These are enforced — the memory cgroup controller is enabled on this host. Verify with:

    docker run --rm --memory=64m alpine sh -c 'cat /sys/fs/cgroup/memory.max'
    # 67108864 = enforced;  "max" = NOT enforced, check /proc/cmdline

Disk is the scarce resource (120GB SSD), not RAM. Watch `df -h /` and `docker system df`.
`docker image prune` is safe here since images are pulled, not built. **Never** prune
volumes blindly — `dbdata` lives there, and it is now the entire database.

---

## Backups

`dbdata` is a Docker volume on the Pi's SSD holding the SQLite files. It is **not**
backed up by anything yet. Configure a scheduled copy to an off-box location before
this holds data you care about.

Use SQLite's `.backup`, which takes a consistent snapshot of a live database. Do **not**
`cp` the file while the app is running: with WAL enabled a plain copy can capture a torn
file, and copying `production.sqlite3` without its `-wal` sidecar loses recent commits.

    docker compose -p <service> exec web \
      sqlite3 /data/production.sqlite3 ".backup '/data/backup.sqlite3'"

Only the primary database needs backing up. `production_cache` and `production_queue`
are regenerable — Solid Cache holds nothing durable and the queue is transient.

---

## Known issue in the existing CI

`.github/workflows/ci.yml` triggers on `push: branches: [ main ]`, but this repository's
default branch is **`master`**. Those jobs will not run on pushes to master. The new
`build-image.yml` targets `master` deliberately. Worth reconciling `ci.yml` separately.
