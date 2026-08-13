# Tasks — Plan 2: bearer-token data layer

Plan: `context/PLAN_DATA_TOKEN_LAYER.md` · Branch `26-data-token-layer` · PR #217 · Fizzy #26

Executed directly (not parallelized): tasks interlock and share files
(`user.rb`, `game.rb`, `routes.rb`, `.mutant.yml`, `docs/AUTHORIZATION.md`), so
subagents would collide. Committed in logical groups.

## Checklist

### Data + model
- [ ] **T1 — Migration `CreateApiTokens`:** `user_id` NN fk, `game_id` NN fk, `scope`
  string NN default "rss", `token` string NN; unique `(user_id, scope, game_id)`,
  unique `token`. Update schema.
- [ ] **T2 — `ApiToken` model:** `# typed: strict`; belongs_to user/game; uniqueness
  scope; `before_validation :generate_token, on: :create`; `regenerate!`;
  `self.generate_secure_token`. `.mutant.yml` + tapioca RBI. Spec.
- [ ] **T3 — Associations:** `user.rb` has_many :api_tokens dependent: :destroy;
  `game.rb` has_many :api_tokens dependent: :destroy.
- [ ] **T4 — GamePurgeJob:** delete api_tokens in `#delete_records`; populate an
  api_token in `spec/jobs/game_purge_job_spec.rb` guardrail.

### Shared query
- [ ] **T5 — `SceneSummary.public_for_game(game)` scope:** extract the public/resolved/
  ordered/includes query; use it in `scene_summaries_controller` and the feed. Spec the
  scope + keep controller covered.

### Auth layer
- [ ] **T6 — `DataApplicationController`:** bearer-only (param + `Authorization: Bearer`),
  no session, `protect_from_forgery :null_session`, Pundit `pundit_user =
  current_data_user`, 401 on missing/invalid, extract `bearer_token`. Spec token
  resolution.
- [ ] **T7 — Feed policy:** `GamePolicy#feed?` (or dedicated) = active member re-check.
- [ ] **T8 — `RssController#feed`:** resolve token→user+game (scope must be "rss"),
  `authorize @game`, load via `public_for_game`, render RSS. Request spec (200/401/403,
  wrong game, wrong scope, revoked, removed-member).
- [ ] **T9 — `app/views/rss/feed.rss.builder`:** RSS XML (restored from teardown),
  targeting @game/@summaries.
- [ ] **T10 — Route:** `get "/rss/feed", to: "rss#feed"` outside `authenticate :user`.

### Token management UI
- [ ] **T11 — `Ui::SecretFieldComponent`:** masked field, show/hide, copy; `secret-field`
  Stimulus + CSS; `# typed: strict`; `.mutant.yml`; spec; Lookbook preview.
- [ ] **T12 — `Profiles::ApiTokensController`:** create/destroy scoped to game_id+scope,
  membership guard, session-authed. Request spec.
- [ ] **T13 — Profile "RSS Feeds" section:** per non-banned membership create/revoke +
  feed URL in SecretFieldComponent; consistent card layout. System spec both viewports.
- [ ] **T14 — Routes for management actions** under `authenticate :user`.

### Docs / registration / verify
- [ ] **T15 — Docs:** `docs/AUTHORIZATION.md` (machine-auth root); `bin/check-authorization`
  if needed; `REQUIREMENTS.md`.
- [ ] **T16 — Verify:** full rspec green; `bin/quality-metrics --check` green; mutation
  above floor; every new class in `.mutant.yml`; no-cred precompile if boot code touched.

## Decisions
(filled in at completion tail)
