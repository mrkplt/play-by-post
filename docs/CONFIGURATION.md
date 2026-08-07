# Configuration — source of truth

**This file is authoritative for every runtime parameter this app reads.** Every entry
below cites the file and line that reads it. If you change a config read site in code,
update this file in the same commit.

Do not duplicate this list elsewhere. `README.md` and `DEPLOY.md` link here instead of
restating values.

**Secrets live in encrypted credentials; env vars carry only non-secret deployment
settings.** Every secret-bearing read site checks
`config/credentials/production.yml.enc` first and falls back to an env var of the same
meaning, so local runs work without the credentials key while production needs only
`RAILS_MASTER_KEY`.

The two mechanisms are separate — nothing copies credentials into `ENV` automatically
(verified: no `ENV[...] =`, `ENV.store`, `ENV.update`, or `ENV.merge` anywhere outside
`BUNDLE_GEMFILE` boot plumbing). The fallback is implemented explicitly at each read site,
listed below.

---

## Which credentials file is live

Rails resolves the credentials path like this
(`railties/lib/rails/application/configuration.rb:643-650`):

    content_path = config/credentials/#{Rails.env}.yml.enc
    content_path = config/credentials.yml.enc      if the above does not exist

    key_path     = config/credentials/#{Rails.env}.key
    key_path     = config/master.key               if the above does not exist

This repo contains `config/credentials/production.yml.enc`, so **in production that file
is the one read and `config/credentials.yml.enc` is ignored entirely.** The matching key is
`config/credentials/production.key`, which takes precedence over `config/master.key` by the
same rule.

`config/credentials.yml.enc` is a stale leftover from before the migration to
per-environment credentials. Do not add values to it; they will not be read in production.

Inspect the live file with:

    bin/rails credentials:show --environment production

### Supplying the key at runtime

Set **`RAILS_MASTER_KEY`** to the contents of `config/credentials/production.key`.

Despite the name, `RAILS_MASTER_KEY` is the env var for *whichever* credentials file is
active — the `env_key` default is `"RAILS_MASTER_KEY"` regardless of content path
(`railties/lib/rails/application.rb:516`), and there is no `RAILS_PRODUCTION_KEY`. The env
var is checked **before** the key file (`activesupport/lib/active_support/encrypted_file.rb:53`),
so no key file needs to exist in the image.

Verified working against this repo: with the key file absent and `RAILS_MASTER_KEY` set to
the production key, `production.yml.enc` decrypts and Active Storage boots.

---

## 1. Environment variables — required

Set these in the Coolify UI. The app is broken without them.

| Variable | Read at | Notes |
|---|---|---|
| `RAILS_MASTER_KEY` | `encrypted_file.rb:53` | Contents of `config/credentials/production.key`. Without it every credential below is unreadable |
| `APP_HOST` | `config/environments/production.rb:74` | Host for mailer links. **Fails silently** — see Traps |

That is the entire list — two variables. The database needs no configuration: it is
SQLite, and `DATABASE_PATH` is set to `/data` in `docker-compose.coolify.yml` rather
than by hand. There is no `DATABASE_URL` and no database password.

**Do not set `SECRET_KEY_BASE`.** It lives in credentials and Rails reads it from there
(verified: with the env var unset, `Rails.application.secret_key_base` resolves to
`credentials.secret_key_base`). Setting it as an env var would override the credential, and
if the two ever diverge, every existing session cookie and signed value stops verifying.

> **This is load-bearing for staying logged in.** Sessions are server-side
> (`activerecord-session_store`, table on the `/data` volume), but the session-id
> cookie *and* the 30-day remember-me cookie are both signed with `secret_key_base`.
> A stable `secret_key_base` is therefore what lets a login survive a deploy. If
> logins drop on every deploy, the first thing to check is whether `secret_key_base`
> is changing between deploys — i.e. whether `SECRET_KEY_BASE` is set in the Coolify
> UI to a value that rotates. It must be unset so Rails reads the stable credential.

**There is no `IMAGE_TAG`.** The compose file pins `:latest`, which the build workflow
publishes on every push to master (`type=raw,value=latest,enable={{is_default_branch}}`).
Enable **"always pull image"** in Coolify, or Docker reuses the cached `:latest` layer and
silently runs stale code. To roll back, edit the compose file to `:sha-<commit>`.

That is the whole required set. Storage and OpenRouter secrets now live in credentials
(next section); their `STORAGE_*` / `OPENROUTER_API_KEY` env vars remain supported as a
fallback for local runs, but should **not** be set in production.

Active Storage uses the `:cloudflare_r2` service in production
(`config/environments/production.rb:39`), so the `storage:` credential block is mandatory
for uploads.

## 2. Environment variables — optional

Safe defaults exist; set only to override.

| Variable | Read at | Default |
|---|---|---|
| `STORAGE_REGION` | `config/storage.yml` | `auto` — correct for R2. Prefer `storage.region` in credentials |
| `OPENROUTER_MODEL` | `app/services/scene_summary_service.rb` | `openai/gpt-4o`. Not a secret, so env var is fine |
| `RAILS_MAX_THREADS` | `config/database.yml:2`, `config/puma.rb:27` | `5` (DB pool) / `3` (Puma). Compose sets `5` |
| `RAILS_LOG_LEVEL` | `config/environments/production.rb:55` | `info` |
| `GLITCHTIP_DSN` | `config/initializers/sentry.rb:6` | unset — falls back from the `glitchtip_dsn` credential; if both are unset, error reporting is disabled entirely |
| `RAILS_LOG_TO_STDOUT` | Rails default | Compose sets `1`; required for Coolify to capture logs |
| `PORT` | `config/puma.rb:31` | `3000`. Thruster terminates HTTP on 80 in front of Puma |
| `WEB_CONCURRENCY` | `config/puma.rb` | Puma worker count |
| `PIDFILE` | `config/puma.rb:44` | unset |

## 3. Environment variables — do NOT set in production

| Variable | Why |
|---|---|
| `SOLID_QUEUE_IN_PUMA` | `config/puma.rb:40` runs Solid Queue inside Puma. The compose file already runs a dedicated `worker` container; setting this double-processes every job |
| `SECRET_KEY_BASE_DUMMY` | Build-time asset precompile only. `config/environments/production.rb:27` disables `require_master_key` when it is present, defeating the credentials guard |
| `RAILWAY_PUBLIC_DOMAIN` | Railway-era fallback for `APP_HOST`. Set `APP_HOST` instead |

## 4. Encrypted credentials

Stored in `config/credentials/production.yml.enc`. Edit with
`bin/rails credentials:edit --environment production`.

| Key | Read at | Required? |
|---|---|---|
| `resend_api_key` | `config/initializers/resend.rb:6` | Yes — outbound email |
| `resend_webhook_secret` | `app/controllers/action_mailbox/ingresses/resend/inbound_emails_controller.rb:54` | Yes — `whsec_…` from the Resend dashboard; inbound webhook verification fails without it |
| `openrouter_api_key` | `app/services/email_content_extractor.rb:22` **and** `app/services/scene_summary_service.rb` | Yes — inbound email parsing *and* scene summaries. Both read the credential; a single value now serves both |
| `storage.access_key_id` | `config/storage.yml` | Yes — Cloudflare R2 |
| `storage.secret_access_key` | `config/storage.yml` | Yes — Cloudflare R2 |
| `storage.bucket` | `config/storage.yml` | Yes — Cloudflare R2 |
| `storage.endpoint` | `config/storage.yml` | Yes — `https://<account_id>.r2.cloudflarestorage.com` |
| `storage.region` | `config/storage.yml` | Optional — defaults to `auto` |
| `resend_inbound_domain` | `app/mailers/notification_mailer.rb:55` | Optional — falls back to `APP_HOST` |
| `glitchtip.dsn` | `config/initializers/sentry.rb:6` | Optional — DSN for the self-hosted GlitchTip instance; falls back to `GLITCHTIP_DSN` env var; error reporting is disabled entirely if both are unset |
| `deploy_webhook_secret` | `app/controllers/webhooks/deploy_controller.rb` | Optional — shared bearer secret GitHub Actions sends to `POST /webhooks/deploy`; must equal the `DEPLOY_WEBHOOK_SECRET` GitHub Actions secret. If unset, the deploy relay rejects all callers |
| `coolify.deploy_url` | `app/jobs/coolify_deploy_job.rb` | Optional — Coolify's per-app deploy URL (`http://<internal-host>:<port>/api/v1/deploy?uuid=<app-uuid>`), reachable over the internal network. Required for auto-deploy |
| `coolify.token` | `app/jobs/coolify_deploy_job.rb` | Optional — Coolify API token sent as `Authorization: Bearer`. Required for auto-deploy |
| `fizzy.api_url` | `app/services/fizzy_sweep_service.rb` | Optional — base URL of the personal Fizzy instance (e.g. `https://fizzy.example.com`). Required for the hourly feedback sweep |
| `fizzy.access_token` | `app/services/fizzy_sweep_service.rb` | Optional — Fizzy personal access token with write permission, sent as `Authorization: Bearer`. Required for the feedback sweep |
| `fizzy.account_slug` | `app/services/fizzy_sweep_service.rb` | Optional — Fizzy account slug used in API paths. Required for the feedback sweep |
| `fizzy.board_id` | `app/services/fizzy_sweep_service.rb` | Optional — Fizzy board that receives the feedback cards. Required for the feedback sweep |
| `secret_key_base` | Rails internal (no explicit read site) | Yes — this is the live source. Do **not** also set the `SECRET_KEY_BASE` env var; it would override this, and divergence invalidates all signed cookies |

Verified present as of this writing: `openrouter_api_key`, `resend_api_key`,
`resend_inbound_domain`, `resend_webhook_secret`, `secret_key_base`. To re-check key names
without exposing values:

    bin/rails credentials:show --environment production \
      | sed -E 's/^([[:space:]]*[A-Za-z0-9_]+:)[[:space:]]*[^[:space:]].*$/\1 <REDACTED>/'

ActionMailbox uses **no ingress password**; the Resend inbound webhook is authenticated by
Svix HMAC-SHA256 signature verification in the controller
(`config/initializers/action_mailbox.rb`).

---

## Traps

**`APP_HOST` fails silently.** `config/environments/production.rb:74` reads:

    ENV.fetch("APP_HOST") { ENV.fetch("RAILWAY_PUBLIC_DOMAIN", "example.com") }

There is no exception when unset — every generated email link just points at
`example.com`. Every other required value fails loudly.

**The decryption key is not in the image.** The Dockerfile copies no key, and
`config/credentials/*.key` is gitignored and absent from the build context
(`config/environments/production.rb:22`). Supply `RAILS_MASTER_KEY` at runtime — see
"Supplying the key at runtime" above. Symptom of getting this wrong: the app boots and
serves pages, but storage, email and LLM features all fail.

**The worker needs the same variables as web.** Scene summaries and Active Storage
processing run as background jobs, so the `worker` service needs `RAILS_MASTER_KEY` and
`APP_HOST` too — not just `web`. It is load-bearing: with Solid Queue, all outbound
email flows through it. If the worker is down, jobs accumulate in the queue database
and wait — nothing is lost, but nothing sends either.

**R2 rejects the AWS SDK's default checksums.** `aws-sdk-s3` >= 1.178 adds a CRC32
checksum to every upload, which R2 refuses alongside the `Content-MD5` Active Storage
already sends: `InvalidRequest: You can only specify one non-default checksum at a
time` — every upload fails. `config/storage.yml` pins
`request_checksum_calculation: when_required` to prevent this. Do not remove it, and
re-test uploads after any `aws-sdk-s3` upgrade.

**`config/credentials/production.key` exists only on the developer machine.** It is
untracked by design. If lost, `production.yml.enc` is unrecoverable and every secret in it
must be reissued from Resend, Cloudflare, and OpenRouter. Back it up to a password manager.

---

## External services to provision

| Service | Purpose | Values to recover |
|---|---|---|
| Resend | Outbound email and inbound webhook | API key, webhook signing secret (`whsec_…`), inbound domain |
| Cloudflare R2 | Active Storage via the S3 API | Access key ID, secret access key, bucket, account endpoint |
| OpenRouter | Inbound email parsing and scene summaries | API key |
| GlitchTip | Error tracking (Sentry-protocol compatible, self-hosted on the Coolify instance) | DSN |

**No Redis, no database server.** The database is SQLite on the `dbdata` volume,
mounted at `/data` in both the web and worker containers. Rails 8 runs SQLite in
WAL mode, which is what makes concurrent access from the two containers safe.

**Backups are now a file copy.** The whole database is `/data/production.sqlite3`
(plus its `-wal` and `-shm` sidecars). Copy it with `sqlite3 … ".backup"` rather
than `cp`, which can capture a torn file mid-write:

```bash
docker compose -p <service> exec web \
  sqlite3 /data/production.sqlite3 ".backup '/data/backup.sqlite3'"
```

---

## Historical note

Earlier revisions of `README.md` and the untracked `.env.example` referenced **Mailgun**
(`MAILGUN_API_KEY`, `MAILGUN_DOMAIN`, `RAILS_INBOUND_EMAIL_PASSWORD`) and **`R2_*`-prefixed**
storage variables. Both are obsolete: email moved to Resend, and the storage variables were
renamed to the `STORAGE_*` prefix in `config/storage.yml`. Those names appear nowhere in the
code and setting them has no effect.
