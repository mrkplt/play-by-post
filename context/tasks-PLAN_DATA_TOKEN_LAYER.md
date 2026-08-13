# Tasks — Plan 2: bearer-token data layer

Plan: `context/PLAN_DATA_TOKEN_LAYER.md` · Branch `26-data-token-layer` · PR #217 · Fizzy #26

Executed directly (not parallelized): tasks interlock and share files
(`user.rb`, `game.rb`, `routes.rb`, `.mutant.yml`, `docs/AUTHORIZATION.md`), so
subagents would collide. Committed in logical groups.

## Checklist

### Data + model
- [x] **T1 — Migration `CreateApiTokens`:** table with user/game fks, scope default
  "rss", unique `(user_id, scope, game_id)` + unique token. Schema updated.
- [x] **T2 — `ApiToken` model:** strict; belongs_to user/game; uniqueness scope;
  scope inclusion (`SCOPES = %w[rss api]`); token generation; `regenerate!`. `.mutant.yml`
  + RBI + spec.
- [x] **T3 — Associations:** user/game `has_many :api_tokens, dependent: :destroy`.
- [x] **T4 — GamePurgeJob:** `ApiToken.where(game_id:).delete_all` added; guardrail
  populated in game_purge_job_spec (populate + record_present? + after-purge assertion).

### Shared query
- [x] **T5 — `SceneSummary.public_for_game(game)`:** extracted; used by both the HTML
  index and the feed; `:db` scope specs cover filter/order/cross-game.

### Auth layer
- [x] **T6 — `DataApplicationController`:** bearer-only (param + Bearer header),
  `null_session`, no Warden, `pundit_user = current_data_user`, 401 on missing/unknown,
  `bearer_token` extracted. Registered as abstract base in check-mutant-coverage.
  Behaviour covered end-to-end by rss_spec (header/param/missing/invalid/no-session).
- [x] **T7 — Feed policy:** `GamePolicy#feed?` (active member) + `ApiTokenPolicy#feed?`
  (scope "rss" AND GamePolicy#feed?). Policy unit spec.
- [x] **T8 — `RssController#feed`:** `authorize token, :feed?` on every path (no
  skip_authorization); loads via `public_for_game`; request spec covers
  200/401(missing,unknown)/403(wrong-scope,removed,banned)/header/no-session.
- [x] **T9 — `app/views/rss/feed.rss.builder`.**
- [x] **T10 — Route:** `get "/rss/feed"` outside `authenticate :user`.

### Token management UI
- [x] **T11 — `Ui::SecretFieldComponent`** + secret-field Stimulus + CSS + spec + preview;
  `.mutant.yml`.
- [x] **T12 — `Profiles::ApiTokensController`:** create (find_or_initialize + rotate) /
  destroy, membership+scope guards; request spec (7 create + 3 destroy cases).
- [x] **T13 — Profile "RSS Feeds" section:** `Shared::RssFeedsSectionComponent` (takes
  `user:`, owns card markup + rows) + system specs (list/create+reveal/revoke).
- [x] **T14 — Routes** nested under profile (`resources :api_tokens, module: :profiles`).

### Docs / registration / verify
- [x] **T15 — Docs:** `docs/AUTHORIZATION.md` machine-auth section + table rows added.
  `REQUIREMENTS.md` — **skipped, file does not exist in this repo** (see decisions).
- [x] **T16 — Verify:** full rspec green (2239 ex); `bin/quality-metrics --check` green
  (all changed files 100% line); all 5 static gates green; mutation re-running to record.

## Decisions
(filled in at completion tail)
