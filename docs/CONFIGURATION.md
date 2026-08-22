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
| `APP_HOST` | `config/environments/production.rb:74`, `app/models/branding.rb` | Host for mailer links **and** the brand URL (`Branding.url` → `https://<host>`, used in the OpenAPI server). **Fails silently** for mailer links — see Traps |

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

### Worker-only: BYOK private-key custody

| Variable | Read at | Notes |
|---|---|---|
| `AI_PRIVATE_KEYS_KEY` | `config/initializers/private_key_encryption.rb` | Contents of `config/ai_private_keys.key`. **Required on `worker`, must NOT be set on `web`.** Decrypts `config/ai_private_keys.yml.enc` — a bespoke credential, separate from `RAILS_MASTER_KEY` — which supplies the Active Record Encryption keys for `PrivateKey`. Without it, `PrivateKey` reads/writes raise `ActiveRecord::Encryption::Errors::Configuration` (`PrivateKeyEncryption::UnavailableKeyProvider`) instead of silently no-oping. (Credential filename and env var stay AI-prefixed deliberately — only the Ruby module/class names generalized.) |
| `AI_KEYS_DATABASE_PATH` | `config/database.yml` (`production.ai_keys`) | **Required on `worker`, must NOT be set on `web`.** Mount point for the `ai_keys` SQLite database (BYOK private keys). `docker-compose.yml` gives `worker` its own volume (`aikeysdata:/ai-keys-data`) distinct from `web`'s `dbdata:/data` — `web` has no volume mounted at this path at all, so even a code bug reaching for `PrivateKey` on `web` has no file to open |

This is a second, independent isolation layer on top of the database split itself — see
`app/models/private_key.rb` and `config/initializers/private_key_encryption.rb` for
the full custody model (`Crypto::CryptoService` does the actual browser-envelope
decryption). Losing `config/ai_private_keys.key` makes every stored BYOK private key
unrecoverable — back it up separately from `RAILS_MASTER_KEY`.

## 2. Environment variables — optional

Safe defaults exist; set only to override.

| Variable | Read at | Default |
|---|---|---|
| `RUNTIME_MODE` | `lib/runtime_mode.rb` (`RuntimeMode`), read at route-draw time in `config/routes.rb` | unset — draws **every** route (default all-in-one process). `api` draws **only the JSON `/api` namespace** (the Cloudflare-bypassing bearer-token data API); `web` draws **everything else** — the Devise/game surface plus the mail ingress (`/mail/inbound`), deploy relay (`/webhooks/deploy`), RSS feed (`/rss/feed`), and Swagger docs (`/api-docs`). Lets the **same image** run a dedicated API-only process on an `api.*` host that bypasses the Cloudflare proxy. The boundary is "is this the JSON data API?", not "does it use a session?". The gate is at route-drawing (an undrawn route is the boundary); eager-load is unchanged. Only the `/up` health check is drawn in every mode, so a container of either mode reports healthy. Coolify container wiring for the `api.*` process is a follow-up |
| `APP_NAME` | `app/models/branding.rb` (`Branding.display_name`); `config/initializers/rswag_ui.rb`, `rswag_api.rb` read `ENV` directly (pre-autoload) | `Play by Post` — the deployment's display name, shown in the layout title, sidebar wordmark, invitation emails, PWA manifest, and API docs. This instance sets `flailwhale.com` |
| `STORAGE_REGION` | `config/storage.yml` | `auto` — correct for R2. Prefer `storage.region` in credentials |
| `OPENROUTER_MODEL` | `app/services/scene_summary_service.rb` | `openai/gpt-4o`. Not a secret, so env var is fine |
| `RAILS_MAX_THREADS` | `config/database.yml:2`, `config/puma.rb:27` | `5` (DB pool) / `3` (Puma). Compose sets `5` |
| `RAILS_LOG_LEVEL` | `config/environments/production.rb:55` | `info` |
| `GLITCHTIP_DSN` | `config/initializers/sentry.rb` (backend Ruby SDK) and `app/models/error_tracking.rb` (`ErrorTracking.dsn`), which the browser SDK tunnel (`ErrorTunnelController` / `ErrorEnvelopeForwardJob`) and the layout read | unset — falls back from the `glitchtip.dsn` credential; if both are unset, error reporting is disabled on **all** surfaces (backend and browser). GlitchTip has no public ingress, so browser events are tunnelled same-origin through `/errors/tunnel` and forwarded to GlitchTip over the backplane — the DSN's own host is never contacted from the browser |
| `RAILS_LOG_TO_STDOUT` | Rails default | Compose sets `1`; required for Coolify to capture logs |
| `PORT` | `config/puma.rb:31` | `3000`. Thruster terminates HTTP on 80 in front of Puma |
| `WEB_CONCURRENCY` | `config/puma.rb` | Puma worker count |
| `PIDFILE` | `config/puma.rb:44` | unset |
| `TURNSTILE_SITE_KEY` | `config/initializers/turnstile.rb` | Cloudflare test site key (always passes). Fallback for the `turnstile.site_key` credential; prefer the credential in production |
| `TURNSTILE_SECRET_KEY` | `config/initializers/turnstile.rb` | Cloudflare test secret key (always passes). Fallback for the `turnstile.secret_key` credential; prefer the credential in production |

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
| `glitchtip.dsn` | `config/initializers/sentry.rb` (backend) and `app/models/error_tracking.rb` (`ErrorTracking`, read by the browser SDK tunnel and the layout) | Optional — DSN for the self-hosted GlitchTip instance, used by **both** the Ruby SDK and the browser SDK; falls back to `GLITCHTIP_DSN` env var; error reporting is disabled entirely if both are unset. Browser events are tunnelled through the app (`/errors/tunnel`) since GlitchTip is not publicly reachable |
| `deploy_webhook_secret` | `app/controllers/webhooks/deploy_controller.rb` | Optional — shared bearer secret GitHub Actions sends to `POST /webhooks/deploy`; must equal the `DEPLOY_WEBHOOK_SECRET` GitHub Actions secret. If unset, the deploy relay rejects all callers |
| `coolify.deploy_url` | `app/jobs/coolify_deploy_job.rb` | Optional — Coolify's per-app deploy URL (`http://<internal-host>:<port>/api/v1/deploy?uuid=<app-uuid>`), reachable over the internal network; the job sends an authorized `POST`. Required for auto-deploy |
| `coolify.token` | `app/jobs/coolify_deploy_job.rb` | Optional — Coolify API token sent as `Authorization: Bearer`. Required for auto-deploy |
| `fizzy.api_url` | `app/services/fizzy_sweep_service.rb` | Optional — base URL of the personal Fizzy instance (e.g. `https://fizzy.example.com`). Required for the hourly feedback sweep |
| `fizzy.access_token` | `app/services/fizzy_sweep_service.rb` | Optional — Fizzy personal access token with write permission, sent as `Authorization: Bearer`. Required for the feedback sweep |
| `fizzy.account_slug` | `app/services/fizzy_sweep_service.rb` | Optional — Fizzy account slug used in API paths. Required for the feedback sweep |
| `fizzy.board_id` | `app/services/fizzy_sweep_service.rb` | Optional — Fizzy board that receives the feedback cards. Required for the feedback sweep |
| `turnstile.site_key` | `config/initializers/turnstile.rb` | **Yes in production** — Cloudflare Turnstile public site key, embedded in the widget. Falls back to `TURNSTILE_SITE_KEY` env, then to Cloudflare's always-pass test key. If left as the test key in prod, the bot check provides **no protection** |
| `turnstile.secret_key` | `config/initializers/turnstile.rb` | **Yes in production** — Cloudflare Turnstile secret key, used server-side by `TurnstileVerifier` against siteverify. Falls back to `TURNSTILE_SECRET_KEY` env, then to the always-pass test key |
| `secret_key_base` | Rails internal (no explicit read site) | Yes — this is the live source. Do **not** also set the `SECRET_KEY_BASE` env var; it would override this, and divergence invalidates all signed cookies |

Verified present as of this writing: `openrouter_api_key`, `resend_api_key`,
`resend_inbound_domain`, `resend_webhook_secret`, `secret_key_base`. To re-check key names
without exposing values:

    bin/rails credentials:show --environment production \
      | sed -E 's/^([[:space:]]*[A-Za-z0-9_]+:)[[:space:]]*[^[:space:]].*$/\1 <REDACTED>/'

ActionMailbox uses **no ingress password**; the Resend inbound webhook is authenticated by
Svix HMAC-SHA256 signature verification in the controller
(`config/initializers/action_mailbox.rb`).

### A second, separate encrypted credential: `config/ai_private_keys.yml.enc`

Deliberately **not** part of `config/credentials/production.yml.enc` above — a different
file, decrypted by a different key (`config/ai_private_keys.key` / `AI_PRIVATE_KEYS_KEY`,
not `RAILS_MASTER_KEY`), read only by `config/initializers/private_key_encryption.rb`.
It supplies Active Record Encryption's `primary_key` / `deterministic_key` /
`key_derivation_salt` for `PrivateKey` specifically (BYOK private keys), not the app-wide
`ActiveRecord::Encryption.config`. See "Worker-only: BYOK private-key custody" above —
this key must reach the `worker` container and must NOT reach `web`. Generate a fresh one
with `ActiveSupport::EncryptedConfiguration.generate_key`; there is no
`bin/rails credentials:edit` shortcut for it (it isn't a Rails `credentials:` file), edit
it by constructing `ActiveSupport::EncryptedConfiguration.new(config_path:, key_path:,
env_key: "AI_PRIVATE_KEYS_KEY", raise_if_missing_key: true)` directly.

| Key | Read at | Required? |
|---|---|---|
| `active_record_encryption.primary_key` | `config/initializers/private_key_encryption.rb` | Yes — without it `PrivateKey` falls back to `PrivateKeyEncryption::UnavailableKeyProvider`, which raises on any encrypt/decrypt |
| `active_record_encryption.deterministic_key` | Generated alongside the others; not currently read (no deterministic `encrypts` column exists yet) | Reserved for a future deterministic (searchable) encrypted column |
| `active_record_encryption.key_derivation_salt` | `config/initializers/private_key_encryption.rb` (`PrivateKeyEncryption::KeyGenerator`) | Yes — this credential's own salt, not the app-wide `ActiveRecord::Encryption.config.key_derivation_salt` (which stays unset; nothing else in this app uses `encrypts`) |

---

## Abuse protection (Turnstile + rate-limiting)

Two independent, layered defenses. See `context/2026-08-12-abuse-protection-plan.md`.

**Cloudflare Turnstile — bot detection on forms.** A mostly-invisible challenge on
the magic-link sign-in form and the feedback modal. Keys resolve
credential → env → Cloudflare's always-pass **test keys** (`config/initializers/turnstile.rb`),
so dev, test, and the credential-less asset-precompile build work with no real keys.

- **You must provision real keys in production credentials** (`turnstile.site_key` /
  `turnstile.secret_key`) before this protects anything. Left on the test key, the
  widget renders but every token passes.
- Server-side verification (`TurnstileVerifier`) **fails open**: if Cloudflare's
  siteverify is unreachable or times out, the request is allowed — rate-limiting
  (below) is the backstop, so a Cloudflare outage can't lock users out of sign-in.
  It fails **closed** only on a blank token or an explicit `success: false`.
- Turnstile is skipped entirely in the test env (`Turnstile.enabled?` is false there);
  specs that exercise it stub `Turnstile.enabled?` to `true`.

**rack-attack — edge rate-limiting (infrastructure hard stop).** Middleware, runs
before Rails, backed by the app's Solid Cache store (`config/initializers/rack_attack.rb`).
No configuration required; limits are code constants:

| Surface | Path | Limits |
|---|---|---|
| Magic-link sign-in | `POST /users/sign_in` | 10/3min per IP · 5/3min per normalized email |
| Invitation accept | `GET /invitations/:token/accept` | 20/min per IP · 10/min per token |
| Inbound email webhook | `POST /mail/inbound` | 30/min per IP (Svix signature is the primary gate) |

Throttled requests get a `429` with `Retry-After`. rack-attack is **disabled in the
test env by default**; throttle specs enable it and swap in a MemoryStore.

House rule: rack-attack is the **edge / infrastructure** layer (coarse IP/token/email
hard stops). Per-actor **application** quotas (e.g. requests/hour per API key) are
reserved for Rails 8.1's controller-level `rate_limit` — not used yet.

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

**The image is split in two: `web` and `worker` no longer run the same image.** The
Dockerfile builds two final stages — `web-final` and `worker-final` — both derived from
the same `base`/`build` stages, so they share one bundle install and one asset
precompile. They diverge only in what lands in `/rails`: `worker-final` copies straight
from `build`; `web-final` copies from an intermediate `app-export` stage that deletes
`config/ai_private_keys.key` and `config/ai_private_keys.yml.enc` (the AI Control
Plane's AR-encryption key file and its encrypted credentials) right after copying. That
means the secret is absent from every layer of the `web-final` image, not filtered out
at runtime — `web` has no code path that could ever read it, by construction. CI
publishes the two stages as two separate GHCR image repositories:
`ghcr.io/mrkplt/play-by-post-web` (`:latest` / `:sha-<sha>`) from `web-final`,
`ghcr.io/mrkplt/play-by-post-worker` (`:latest` / `:sha-<sha>`) from `worker-final`.
`docker-compose.yml` pins `web` and `worker` to `:latest` of their respective images.
**"Enable always pull image" in Coolify applies to both services** — the stale-cache trap described above under "There
is no `IMAGE_TAG`" now applies twice.

**`worker-keys` is a worker-only volume, separate from `dbdata`.** It holds the AI
Control Plane's private-key SQLite database, mounted at `/keys` only in the `worker`
service. `web` does not mount it and the `web-final` image has no `/keys` directory —
so even an attacker with full control of the web container has no volume through which
to reach the private-key database, on top of the image never holding the decryption
key. Back it up the same way as `dbdata` (`sqlite3 …  ".backup"`, not `cp`).

---

## The data API

The token-authenticated `/api` surface (pages + notebook entries; see ARCHITECTURE
"The machine-auth surface") needs no configuration or secrets of its own — it
authenticates by a bearer `ApiToken`, not an env var.

- **Docs / contract:** Swagger UI at **`/api-docs`**, backed by the committed
  `openapi/v1/openapi.yaml`. That document is generated from the `/api` request
  specs (`RAILS_ENV=test bundle exec rake rswag:specs:swaggerize`); the
  `bin/check-openapi-fresh` gate fails the build if the committed copy has drifted.
  It is also what `Api::SchemaValidation` validates live requests against.
- **Issuing a token:** a signed-in user mints and revokes their own `api`-scoped
  tokens from their **profile** page (the "API tokens" section). A token is valid
  only while its user is an active member of the game it was minted for.

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

**Four SQLite databases share the `dbdata` volume.** `config/database.yml`
`production` connects to `primary` (`production.sqlite3` — the real data),
`cache` (Solid Cache), `queue` (Solid Queue), and `cable`
(`production_cable.sqlite3` — Solid Cable's Action Cable message backplane).
The cache/queue/cable three are schema-owned (they load `cache_schema.rb` /
`queue_schema.rb` / `cable_schema.rb` and point `migrations_paths` at an empty
directory so the primary's migrations are not duplicated into them). The `cable`
database is what lets the **worker broadcast a Turbo Stream the web container's
subscribers receive** — e.g. an AI scene summary pushed to the scene page when
`SceneSummaryJob` finishes (`app/models/scene_summary_broadcast.rb`, subscribed
via `SceneSummaryChannel`). It lives on the **shared** `dbdata` volume, NOT the
worker-only `aikeysdata` volume, so it adds no new web↔worker coupling and does
not touch the BYOK key isolation. Action Cable mounts at `/cable` (Rails
default); `config/cable.yml` selects the `solid_cable` adapter in production and
`async`/`test` in development/test.

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
