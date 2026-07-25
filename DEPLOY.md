# Deploying play-by-post to PiHost (Coolify)

Target: **PiHost** — Raspberry Pi 4, 8GB, aarch64, Debian 13, at `10.0.0.192`.
Coolify dashboard: `http://10.0.0.192:8000` (LAN only, plain HTTP).

Model: **build off-device, pull on the Pi.** Images are built by GitHub Actions and
pulled from GHCR. Do not build on the Pi — its USB-SATA bridge runs without command
queuing, so builds are slow and IO-heavy.

---

## Stack

Three containers. **No Redis** — this app uses Solid Queue and Solid Cache, both
Postgres-backed.

    web        ghcr.io/mrkplt/play-by-post   Thruster + Puma on :80
    worker     same image                    bundle exec rake solid_queue:start
    postgres   postgres:17-alpine            named volume `pgdata`

`config/database.yml` defines **three production databases** — primary, `_cache` and
`_queue` — each with its own migration path. `bin/docker-entrypoint` runs `db:prepare`
when the server starts, which creates and migrates all three. The worker does not run
migrations, which is correct: only one process should.

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
of `docker-compose.coolify.yml`.

Set these as **Environment Variables in the Coolify UI** — never commit them:

    IMAGE_TAG           sha-<commit>   pin explicitly; avoid `latest` so redeploys are deterministic
    POSTGRES_PASSWORD   strong random value
    SECRET_KEY_BASE     output of `rails secret`

Note `SECRET_KEY_BASE_DUMMY=1` is used at *build* time for asset precompilation only. The
runtime value must be a real secret supplied here.

---

## 4. Verify

    docker compose -p <service> ps
    # web, worker, postgres all Up; postgres and web healthy

    docker compose -p <service> logs --tail 50 web
    # look for db:prepare completing and Puma booting

    docker compose -p <service> logs --tail 50 worker
    # SolidQueue::Supervisor started

    docker compose -p <service> exec postgres \
      psql -U play_by_post -d play_by_post_production -c '\l'
    # primary, _cache and _queue databases present

The web container has a healthcheck against `/up` (`rails/health#show`, confirmed present
in `config/routes.rb`). `curl` is installed in the image's base stage, so the check works.

---

## 5. Routing

Assign a domain/host in the Coolify UI for the `web` service. Traefik routes to it by
hostname on ports 80/443.

**Let's Encrypt HTTP-01 cannot validate against a private address** (10.0.0.192) — the CA
cannot reach the host from the internet. Options:

- **LAN-only over HTTP** — simplest, fits the current posture.
- **DNS-01 challenge** against a domain you control — real certificates, no inbound ports.
- **Tunnel** (e.g. Cloudflare Tunnel) if the app genuinely needs public reachability.

---

## Resource budget

Memory limits total ~2.75GB of the Pi's 8GB, leaving room for Coolify (~0.8GB) and headroom:

    web        1g
    worker     768m
    postgres   1g

These are enforced — the memory cgroup controller is enabled on this host. Verify with:

    docker run --rm --memory=64m alpine sh -c 'cat /sys/fs/cgroup/memory.max'
    # 67108864 = enforced;  "max" = NOT enforced, check /proc/cmdline

Disk is the scarce resource (120GB SSD), not RAM. Watch `df -h /` and `docker system df`.
`docker image prune` is safe here since images are pulled, not built. **Never** prune
volumes blindly — `pgdata` lives there.

---

## Backups

`pgdata` is a Docker volume on the Pi's SSD. It is **not** backed up by anything yet.
Configure scheduled `pg_dump` to an off-box location before this holds data you care about.

---

## Known issue in the existing CI

`.github/workflows/ci.yml` triggers on `push: branches: [ main ]`, but this repository's
default branch is **`master`**. Those jobs will not run on pushes to master. The new
`build-image.yml` targets `master` deliberately. Worth reconciling `ci.yml` separately.
