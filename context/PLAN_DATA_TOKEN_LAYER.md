# Plan 2 — Build-up: generic bearer-token data layer, RSS as first consumer

**Branch:** `26-data-token-layer` (cut off updated `origin/master` **after** Plan 1
merges) · One PR.

Introduce machine-auth as a first-class boundary separate from session auth, and
re-implement the RSS feed on top of it. This is the foundation the API will be built on.

## Decisions (locked by the owner)

- **Feed URL shape:** `/rss/feed?token=T` — token-only. The token *is* the game
  credential; the game is not in the path.
- **Token model name:** `ApiToken` (forward-looking; the API is the point of the layer).
- **Management controller:** a **dedicated** `Profiles::ApiTokensController` — not
  actions bolted onto `ProfilesController`. Especially important as API controls grow;
  keeps things from getting messy.
- **Token authority:** identity-only. A Pundit policy re-checks active membership on
  every request; removed member → feed dies next fetch.
- **Token→game binding:** one token per (user, scope, game); `game_id` **NOT NULL**. No
  account-wide token (that was the reverted #214 shape).
- **Layout consistency:** keep shared visual chrome; do not strip components guessed to
  be unneeded (the lesson from the reverted attempt).

## Architecture

- **`DataApplicationController < ActionController::Base`** — a **sibling** to
  `ApplicationController`, not a child. It:
  - authenticates by **bearer token only**: accepts `params[:token]` and
    `Authorization: Bearer …`;
  - never invokes Warden/Devise, never establishes a session cookie
    (`protect_from_forgery with: :null_session`);
  - exposes `current_data_user` and the resolved `current_api_token`;
  - on missing/invalid token → `head :unauthorized`;
  - `include Pundit::Authorization` with `pundit_user` → `current_data_user`.
  This is the base every machine-facing controller (RSS now, API later) inherits from.
  The point is that machine auth and application auth can never accidentally share a
  session.

- **`ApiToken`** (generalized from the deleted `RssToken`) — `belongs_to :user`,
  `belongs_to :game`, `scope` string (`"rss"` now; `"api"` later), secure `token`,
  `regenerate!`. Uniqueness `(user_id, scope, game_id)`; `game_id` NOT NULL. Token
  generation as before (`SecureRandom.hex(32)`).

- **`RssController < DataApplicationController`**, action `#feed` at
  `GET /rss/feed?token=T`. Resolves user+game from the token (scope must be `"rss"`),
  then `authorize @game, :feed?` via a policy that re-checks active membership each
  request. Renders the RSS builder (moved from Plan 1's deleted
  `scene_summaries/index.rss.builder`).

## Changes

### Data
1. Migration `CreateApiTokens` (fresh table — Plan 1 dropped `rss_tokens`):
   `user_id` NOT NULL fk, `game_id` NOT NULL fk, `scope` string NOT NULL default
   `"rss"`, `token` string NOT NULL. Unique index `(user_id, scope, game_id)`; unique
   index on `token`. Update `db/schema.rb`.
2. `app/models/api_token.rb` — `# typed: strict`; associations; uniqueness scope;
   `before_validation :generate_token, on: :create`; `regenerate!`;
   `self.generate_secure_token`. Add to `.mutant.yml`. `bundle exec tapioca dsl` for
   its RBI.
3. `app/models/user.rb` — `has_many :api_tokens, dependent: :destroy`.
4. `app/models/game.rb` — `has_many :api_tokens, dependent: :destroy`.
   **`GamePurgeJob` must delete `api_tokens`** — add to `#delete_records`, and populate
   an `api_token` in `spec/jobs/game_purge_job_spec.rb` so a missed table fails the
   suite (the domain-model guardrail in CLAUDE.md).

### Auth layer
5. `app/controllers/data_application_controller.rb` — as described. Extract token
   resolution (Authorization header + `token` param) into a small, directly tested
   private method (`bearer_token`). Sigil per the metaprogramming rule (`# typed: false`
   only if it does `prepend`/`class_eval`; otherwise `# typed: true`).
6. `app/controllers/rss_controller.rb` — `#feed`: resolve token → user + game (reject
   if `scope != "rss"`); `authorize @game`; load summaries via a **shared** query so the
   HTML index and the feed agree — extract `SceneSummary.public_for_game(game)` (public,
   resolved, ordered by `resolved_at DESC`, `includes(:scene)`) and use it in both
   places; render RSS.
7. Feed authorization — `GamePolicy#feed?` (or a dedicated `ApiTokenPolicy`):
   `record.active_members.exists?(user: user)` where `user` is `current_data_user`.
8. `app/views/rss/feed.rss.builder` — the RSS XML restored from Plan 1's deleted
   `index.rss.builder`, retargeted at `@game` / `@summaries`.

### Routing
9. `config/routes.rb` — `get "/rss/feed", to: "rss#feed"`, **outside** `authenticate
   :user` (token auth, not session). No `:game_id` in the path.

### Token management UI (profile)
10. `Ui::SecretFieldComponent(value:, label:)` — read-only field masked by default
    (dots), show/hide toggle, copy-to-clipboard (always copies the real value). Small
    `secret-field` Stimulus controller + component CSS. `# typed: strict`, `.mutant.yml`,
    spec (all states), Lookbook preview. (The one salvageable idea from #214.)
11. `Profiles::ApiTokensController` (dedicated) — `create` / `destroy` scoped to a
    `game_id` + `scope` (guard: current_user is a non-banned member of that game).
    Session-authed (inherits `ApplicationController`).
12. Profile "RSS Feeds" section: list the user's non-banned game memberships; per game,
    show create / revoke, and when a token exists render the full feed URL
    (`rss_feed_url(token: token.token)`) in a `Ui::SecretFieldComponent`. **Keep layout
    consistent** with the existing profile sections (`SectionLabelComponent` +
    card-styled rows) — do not invent bespoke markup.
13. Routes for the management actions, under `authenticate :user`, nested to convey
    game + scope (e.g. `resources :api_tokens, only: %i[create destroy]` inside the
    profile, taking `game_id`/`scope` params).

### Docs / registration
14. `docs/AUTHORIZATION.md` — document the machine-auth surface and
    `DataApplicationController` as a distinct authorization root (its controllers
    authorize via `pundit_user = current_data_user`; no allowlist exemption).
    `bin/check-authorization` — teach it the new controller base if needed (RSS/API
    controllers still call `authorize`).
15. `REQUIREMENTS.md` — the token-management feature and feed behavior.

### Specs
- `ApiToken` model (uniqueness scope, token generation, `regenerate!`).
- `DataApplicationController` — token resolution: header form, param form, missing,
  invalid → 401; `current_data_user` wiring.
- `RssController#feed` request spec — valid token 200 + `application/rss+xml`; wrong
  game's token (or wrong scope) rejected; revoked token 401; removed-member re-check 403.
- `Ui::SecretFieldComponent` — masked default, toggle, copy target.
- `Profiles::ApiTokensController` request spec + a profile system spec at both viewport
  sizes if it adds interactive chrome.
- `GamePurgeJob` guardrail (task 4).

## Verification
- `bin/pre-push`, then full `bundle exec rspec` green before `bin/quality-metrics
  --check`.
- No-credentials precompile sanity check if any initializer / boot-time storage code is
  touched (unlikely here).
- Mutation `--since origin/master` covers new controllers/model/component — lift each
  new subject above the floor with real tests; register every new class in `.mutant.yml`
  first.

## Notes
- No ERB ternary / `||` / local-assign in output tags — extract to
  presenter/component/helper.
- Every prose textarea in the new UI (none expected here) would need the markdown
  toolbar; the token UI has no prose fields.
- Keep machine-auth strictly separate: `DataApplicationController` must never read or
  write the session, and `ApplicationController` controllers must never accept the
  bearer token.
