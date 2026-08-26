# Deploying PR #259 (AI Control Plane) — env var setup

CI is green, but the deploy needs **one new secret** wired up: the worker's AI
private-key encryption credential. Everything else you already have set from
prior deploys. This guide is only the delta for #259.

---

## TL;DR

You add **one** env var, to the **worker service only**:

| Var | Set on | Value |
|---|---|---|
| `AI_PRIVATE_KEYS_KEY` | **worker** (NOT web) | The contents of a freshly generated `config/ai_private_keys.key` — see below |

There is a catch: the `config/ai_private_keys.yml.enc` committed on this branch
was encrypted with a throwaway key that no longer exists, so it **cannot be
decrypted** and must be **regenerated** together with its key. Both the
regenerated `.enc` (committed) and the key value (into `AI_PRIVATE_KEYS_KEY`)
come out of the one step below.

---

## Why (30-second version)

- `AiPrivateKey` (players'/games' BYOK private keys, on the worker-only DB) is
  encrypted at rest via Active Record Encryption.
- Those AR-encryption keys live in `config/ai_private_keys.yml.enc`, a **bespoke
  encrypted credential separate from `RAILS_MASTER_KEY`**.
- `config/ai_private_keys.yml.enc` is decrypted by `config/ai_private_keys.key`.
- The `.key` is **gitignored** (never committed) and supplied at runtime as
  `AI_PRIVATE_KEYS_KEY` — **to the worker only.** The web image doesn't even
  contain the `.key`, and the web container must not receive the env var.

---

## Step 1 — Regenerate the credential + key (run locally, in this repo)

The committed `.enc` is unusable (its key is gone). Generate a fresh pair:

```bash
# 1a. Generate the decryption key file (32-char key). This writes config/ai_private_keys.key.
bin/rails runner 'File.write("config/ai_private_keys.key", ActiveSupport::EncryptedConfiguration.generate_key)'

# 1b. Write the encrypted credential's contents. The initializer expects a YAML
#     doc with an active_record_encryption block holding primary_key +
#     key_derivation_salt. Generate real random values and encrypt them:
bin/rails runner '
  c = ActiveSupport::EncryptedConfiguration.new(
    config_path: "config/ai_private_keys.yml.enc",
    key_path:    "config/ai_private_keys.key",
    env_key:     "AI_PRIVATE_KEYS_KEY",
    raise_if_missing_key: false
  )
  c.write(<<~YAML)
    active_record_encryption:
      primary_key: #{SecureRandom.hex(32)}
      deterministic_key: #{SecureRandom.hex(32)}
      key_derivation_salt: #{SecureRandom.hex(32)}
  YAML
'
```

This produces two files:
- `config/ai_private_keys.yml.enc` — **commit this** (it ships in the image; it's
  ciphertext, useless without the key).
- `config/ai_private_keys.key` — **do NOT commit** (it's gitignored). This file's
  contents are the value you paste into the env var in Step 3.

Commit the regenerated `.enc` to the branch and let CI re-run:

```bash
git add config/ai_private_keys.yml.enc
git commit -m "Regenerate ai_private_keys credential for deploy"
git push
```

---

## Step 2 — Get the value to paste

The env var value is the **entire contents** of the key file (a single 32-char
hex line, no newline noise):

```bash
cat config/ai_private_keys.key
```

Copy that string. Keep it somewhere safe (a password manager) — if you lose it,
every stored BYOK key becomes undecryptable and players must re-enter their keys
(which is the intended failure mode, but avoid it).

---

## Step 3 — Set it in Coolify

In the Coolify project for this app, on the **worker** service's Environment
Variables (NOT the web service):

| Name | Value |
|---|---|
| `AI_PRIVATE_KEYS_KEY` | *(paste the contents of `config/ai_private_keys.key`)* |

You do NOT need to set these — they are already baked into `docker-compose.yml`:

- `AI_KEYS_DATABASE_PATH: /ai-keys-data` — a **hardcoded literal** on the worker
  service (not `${interpolated}`), so there is nothing to configure. It's the
  mount point for the worker-only BYOK DB, present only on `worker`.
- The worker's own volume `aikeysdata:/ai-keys-data` — declared in the compose
  file (confirm Coolify created the volume, but you don't define it).
- `RAILS_MASTER_KEY` / `APP_HOST` — your existing values, unchanged.

**The ONLY thing you manually configure for this deploy is
`AI_PRIVATE_KEYS_KEY`** (above). Everything else is in the compose file.

**Do NOT set `AI_PRIVATE_KEYS_KEY` or `AI_KEYS_DATABASE_PATH` on the web
service.** The whole custody design depends on the web tier never having them.

### CRITICAL — Coolify Build vs Runtime flags for `AI_PRIVATE_KEYS_KEY`

The `docker-compose.yml` references the key ONLY under the `worker` service
(`AI_PRIVATE_KEYS_KEY: ${AI_PRIVATE_KEYS_KEY}`). But Coolify, by default, marks
every env var as BOTH a Build Variable and a Runtime Variable — and the Runtime
setting writes the var into a `.env` that Compose loads broadly, which can inject
it into BOTH containers, defeating the compose-level scoping.

To keep it worker-only, set the flags on `AI_PRIVATE_KEYS_KEY` in Coolify to:

| Flag | Set to | Why |
|---|---|---|
| **Build Variable** | **ON** | so `${AI_PRIVATE_KEYS_KEY}` interpolates into the worker service's `environment:` block when Coolify processes the compose |
| **Runtime Variable** | **OFF** | so it is NOT written into the broad runtime `.env` that Compose would inject into every container |

With Runtime OFF, the value reaches the container only via the compose file's
explicit worker-only `environment:` line — not via blanket injection.

**Verify it worked (this is the ground truth, don't skip it):** after deploy,
inspect the WEB container and confirm the var is ABSENT, and present on worker:

```bash
docker inspect <web-container>    | grep -i AI_PRIVATE_KEYS_KEY   # expect: nothing
docker inspect <worker-container> | grep -i AI_PRIVATE_KEYS_KEY   # expect: present
```

If it shows up on web, the flags are wrong — the custody boundary is breached.

(`AI_KEYS_DATABASE_PATH` is a literal set in the compose file directly, not a
secret, so its flags don't matter — but it's also worker-only via the compose.)

---

## Step 4 — Two images (nothing to configure; just don't override it)

This PR splits the single image into TWO, published as two separate GHCR image
repositories on merge:
- `ghcr.io/mrkplt/play-by-post-web:latest`
- `ghcr.io/mrkplt/play-by-post-worker:latest`

`docker-compose.yml` already pins each service to its own image (`web` →
play-by-post-web, `worker` → play-by-post-worker). That's the whole point of the
split: the **worker** image carries the private-key credential; the **web** image
does not.

You don't configure this — but make sure Coolify deploys **from this compose
file** (docker-compose deployment) so it honors the two per-service tags, rather
than overriding both services to a single image.

---

## Sanity check after deploy

- Worker boots without `ActiveRecord::Encryption::Errors::Configuration` in logs
  (that error = `AI_PRIVATE_KEYS_KEY` missing/wrong on the worker).
- Web boots fine with the key ABSENT (it resolves lazily to
  `UnavailableKeyProvider` and never needs to decrypt).
- Add a BYOK key via the Profile UI; a scene summary generates on the worker.

---

## The values, in one table

Only the first row is something you set. The rest are already in the compose
file or already configured from prior deploys — listed for completeness.

| Env var | You set it? | Where the value comes from | On |
|---|---|---|---|
| `AI_PRIVATE_KEYS_KEY` | **YES** (Build ON / Runtime OFF) | contents of `config/ai_private_keys.key` (Step 1) | **worker only** |
| `AI_KEYS_DATABASE_PATH` | no — literal in compose | `/ai-keys-data` | worker only |
| `RAILS_MASTER_KEY` | no — already set | `config/credentials/production.key` | both |
| `APP_HOST` | no — already set | your host, e.g. `flailwhale.com` | both |

Not env vars, but part of the deploy (handled by `docker-compose.yml`, nothing
to configure): the two images (`play-by-post-web:latest` /
`play-by-post-worker:latest`, one per service) and the worker-only `aikeysdata`
volume.
