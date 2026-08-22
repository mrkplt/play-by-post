# Architecture

**Read when:** orienting in the codebase, or changing the domain model.
One rule here is load-bearing beyond orientation: any new association or attachment under a `Game` requires a `GamePurgeJob` update.

---

## Codebase Structure

Standard Rails layout plus these non-standard additions:

```
app/
  components/          # ViewComponent — two namespaces:
    ui/                #   Ui::* — primitive, reusable (Badge, Button, Breadcrumb)
    shared/            #   Shared::* — domain-specific (PostItem, PostComposer, Sidebar, SceneCard)
  presenters/          # Draper — BasePresenter < SimpleDelegator, one per model
    base_presenter.rb
    post_presenter.rb  # (+ game_file, scene, user)

config/
  initializers/
    warden_hooks.rb    # Warden::Manager.after_set_user — updates last_login_at on every auth

sorbet/
  rbi/                 # Generated RBI files (tapioca + shims)
  config/              # sorbet/config

spec/
  requests/            # Request specs — one file per controller
  components/          # ViewComponent specs
  presenters/          # Presenter unit specs
  support/
    sign_in_helper.rb          # system spec auth (Capybara)
    request_sign_in_helper.rb  # request spec auth (Warden)

tests/
  integration/         # Manual testing plans (markdown, not RSpec)

.mutant.yml            # Mutation testing config — all tested classes must be listed here
bin/
  pre-push             # Fast local gate — static checks + non-system specs (runs on every push)
  full-check           # Full pipeline on demand — pre-push + system specs + mutation + quality gate
  quality-metrics      # Coverage/mutation/typing metric collector and gate checker
```

---

## Domain Model

```
User → GameMember → Game → Scene → Post
                         → GameFile
                         → Character → CharacterVersion
                         → Invitation
User → SceneParticipant → Scene
User → NotificationPreference → Scene
User → UserProfile
Post → PostRead
```

Key model notes:
- `GameMember` role: `game_master` | `player`; status: `active` | `removed` | `banned`
- `Post` — markdown body, editable within 10-min window (`editable_by?`), draft support — see REQUIREMENTS.md
- `UserProfile` — display_name, hide_ooc, last_login_at (updated by Warden hook on every sign-in) — see REQUIREMENTS.md
- `Invitation` — email + token + accepted_at
- `Game` deletion is two-phase: soft delete (`deleted_at`, hidden by a `default_scope`) then a scheduled purge. **The purge does NOT use `dependent:` cascades** — `GamePurgeJob` collects and deletes a game's records and Active Storage artifacts explicitly, child-first. **Adding any association under a game, or any attachment to a record below a game, means `GamePurgeJob` (`#delete_records` / `#purge_artifacts`) MUST be updated too**, or those rows/blobs are orphaned on purge. The end-to-end spec in `spec/jobs/game_purge_job_spec.rb` is the guardrail — populate the new record/attachment there so a missed table fails the suite. See REQUIREMENTS "Game Deletion".
- **`EncryptedValue` / `PublicKey` / `PrivateKey`** — a general "seal a value to a public key, decrypt on the worker" custody primitive (extracted out of, and de-AI'd from, its first consumer). `EncryptedValue` (owner, polymorphic; `value_type` e.g. `"openrouter_key"`; `sealed_value`, the browser-sealed envelope) is the consumer-facing record — an owner can hold many EncryptedValues, one per `value_type`, each with its OWN dedicated keypair (keypairs are free). `EncryptedValue` belongs to one `PublicKey` (1:1); `PublicKey` has one `PrivateKey` (1:1, cross-database — see below). `EncryptedValue`/`PublicKey` live in the PRIMARY database, readable by `web` so the browser can fetch the public key and encrypt a value to it client-side. `PrivateKey` is split across TWO physical SQLite databases via Rails multi-database (`connects_to`), the same mechanism Solid Queue/Solid Cache use (`config/database.yml`) — it lives in the `ai_keys` db (`app/models/keys_record.rb`), worker-only in production: its own mounted volume (`docker-compose.yml`), and its `encrypted_private_key` column is further encrypted at rest via Active Record Encryption keyed by a bespoke credential only the worker container receives (`config/ai_private_keys.yml.enc`, `config/initializers/private_key_encryption.rb`; NOT `RAILS_MASTER_KEY` — filenames/env vars kept AI-prefixed deliberately, see `docs/CONFIGURATION.md`). `PublicKey`/`PrivateKey` are **not associated** — `connects_to` boundaries don't support `belongs_to`/`has_one` — they're linked by a plain `public_key_id` integer, looked up explicitly (`PublicKey#private_key`, `PrivateKey#public_key`). `Crypto::CryptoService` decrypts the browser's WebCrypto-produced hybrid envelope (RSA-OAEP-256-wrapped AES-256-GCM); see its class comment for the exact blob format. The BYOK (bring-your-own OpenRouter key) feature — `Profiles::ByokKeysController`, `AiKeyResolver`, `Crypto::StoredKeySource` — is the current sole consumer, using `value_type: "openrouter_key"`; `User#ai_key_present?` checks for a sealed EncryptedValue of that type. **A key is real money, so only a person owns one — `EncryptedValue.owner` is always a `User`, never a `Game`** (the column is polymorphic in shape but validated to `User`). A game does not own a key: people own keys and **make them available** to a game via **`GameKeyAuthorization`** (one row per `[game, user, feature]`). A game-level AI feature (see `Ai::Feature`, the registry of every feature + its `:game`/`:personal`/`:app_infra` level) is funded from the game's **pool** — the members who authorized their key for that feature and still have one. `AiKeyResolver` hands the worker a shuffled pool of candidate keys; `Ai::Funding` pops and tries each, failing over on a key-attributable OpenRouter error (401/402/403/429) and aborting on anything else. **Any member's key may fund a game-level output — the GM is not privileged.** People manage their contributions from the Profile ("Fund AI for your games" matrix → `Games::KeyContributionsController`). Full config/isolation details: `docs/CONFIGURATION.md` "Worker-only: BYOK private-key custody".
- **`SceneSummary`** — one per scene (unique `scene_id`), holds the campaign-log prose; `generated_at` non-null marks AI provenance, `draft` gates visibility. Written by `SceneSummaryJob` (worker) after a scene resolves when the game has AI summaries on. **Async delivery to the scene page is a broadcast, not polling** (Fizzy #115/#116): the job finishes and `SceneSummaryBroadcast` (`app/models/scene_summary_broadcast.rb`) pushes a Turbo Stream over Action Cable / Solid Cable to the viewers waiting on the page. Because a summary's visibility differs per viewer (a draft → managers only; an AI summary → hidden from `hidden`-preference viewers — `SceneSummary#visible_to?`), the broadcast is **partitioned by visibility class** (`SceneSummaryVisibility`: `manager` / `plain` / `hidden`): the scene page subscribes each viewer to `[scene, :summary, <their class>]` and the worker broadcasts only to the classes entitled to see the summary. `SceneSummaryChannel` authorizes each subscription (a viewer may join only their own class's stream; the signed stream name plus this check is the gate). The `cable` message-backplane DB is on the shared `dbdata` volume — see `docs/CONFIGURATION.md` "Four SQLite databases".

---

## Routes

Run `rails routes` for the full list. Root → `games#index`. All routes require authentication except `invitations#accept`.

Key named helpers: `game_path`, `game_scene_path`, `game_scene_post_path`, `game_player_management_path`, `game_game_files_path`, `game_character_path`, `profile_path`, `accept_invitation_path`, `user_magic_link_path`.

Dev only: `/letter_opener` (email preview).

## The machine-auth surface (`DataApplicationController`)

Two authentication models live side by side. Most of the app is session-authed
through `ApplicationController` (Devise/Warden). A separate **machine-auth
surface** is a *sibling* of `ApplicationController` — `DataApplicationController`
— that never touches Warden, sets no session cookie, and authenticates a request
solely by a bearer **`ApiToken`** (`Authorization: Bearer <token>` or a `token`
param). The token carries the user *and the game*, so these routes take no
`:game_id` in the path. Pundit runs with the token's user as `pundit_user`, and
authorization (active membership) is re-checked on every request, so a revoked
membership disables access even while the token still exists.

Three consumers:

- **`GET /rss/feed`** (`RssController`) — the campaign-log RSS feed (`ApiToken`
  scope `"rss"`).
- **`/api/pages` and `/api/notebook_entries`** (`Api::PagesController`,
  `Api::NotebookEntriesController` under `Api::BaseController`) — a JSON data API
  (`ApiToken` scope `"api"`) offering **CRU** (create/read/update, no delete)
  over the token's game's pages and notebook entries. Bodies are **raw markdown**;
  records are addressed by their 16-char **slug**. Pages are member-readable /
  GM-write; notebook entries are GM-only in every direction. `Api::BaseController`
  sets `Current.user` to the token's user so API writes attribute their version
  snapshots (see Versionable) correctly.

**OpenAPI as one source of truth.** `openapi/v1/openapi.yaml` is generated from
the `/api` request specs (`rake rswag:specs:swaggerize`) and drives three things:
the Swagger UI at `/api-docs`, the machine-readable contract API clients read, and
**live request validation** — `Api::SchemaValidation` (a small Rack middleware in
`lib/api`) validates each `/api` request body against that document via
`json-schema`, rejecting a schema violation with a `400` before it reaches a
controller. Business-rule failures (e.g. a blank title) remain a model-validation
`422`. `bin/check-openapi-fresh` fails the build if the committed document has
drifted from the specs.

Users mint and revoke their own `ApiToken`s (both scopes) from their profile
(`Profiles::ApiTokensController`), signed in; the tokens are then used against
the machine-auth surface without a session.

