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

### Design decisions made during the run
- **Feed authorization lives in `ApiTokenPolicy#feed?`, authorizing the token** (not
  `authorize @game`). The plan offered either; a token policy that checks scope AND
  delegates membership to `GamePolicy#feed?` is the cleaner pairing and — critically —
  let us **eliminate `skip_authorization` entirely** (owner raised a concern about it).
  Every path through `RssController#feed` now calls `authorize`; wrong-scope and
  non-member are 403 policy denials, missing/unknown token is a 401 from the auth layer
  before Pundit. `AuthorizationNotPerformedError` is deliberately left as a loud dev
  tripwire (never rescued to a quiet 401) — surfaced this reasoning to the owner.
- **`DataApplicationController` registered as an abstract base** in
  `check-mutant-coverage` BASE_FILENAMES (like `ApplicationController`), not a mutation
  subject; its behaviour is covered end-to-end by `rss_spec`.
- **`Shared::RssFeedsSectionComponent` takes `user:` and derives its own data** rather
  than receiving controller ivars. This was forced by the `check-controller-ivars`
  ratchet (adding `@rss_tokens_by_game` to `ProfilesController#show` failed it); the
  component-owns-its-data shape is also the better design.
- **Card markup moved into the component**, not the profile view — the initial inline
  `bg-card …` wrapper on `profiles/show.html.erb` tripped the view-CSS ratchet (+5); the
  wrapper now lives in the component template where component CSS is tracked.
- **No concerns** used (owner reminder): the shared query is a `SceneSummary` class
  method; the base controller is a plain sibling of `ApplicationController`.

### Deviations from the plan
- **`REQUIREMENTS.md` (plan T15) not delivered — file does not exist anywhere in the
  repo** (`find . -iname REQUIREMENTS*` is empty). There was nothing to update and
  creating a whole requirements doc was out of scope. The feature is fully documented in
  `docs/AUTHORIZATION.md` (new machine-auth section) + code comments. (The `REQUIREMENTS`
  references in existing `game_policy.rb` comments are a pre-existing dangling reference,
  not introduced here.) Evaluator confirmed this is the single unaddressed line item;
  impact low.

### Independent evaluator (agent) — verdict CONFORMS
- All plan items verified against the diff. Only gap: REQUIREMENTS.md (moot, above).
  Noted a minor test-coverage nit (no explicit cross-game token test) — **addressed**:
  added "a token for game A never serves game B" to `rss_spec`.

### Independent security code review (agent) — verdict CLEAN, no vulnerabilities
Verified: no session leakage (no Set-Cookie), no IDOR (destroy scoped to
`current_user.api_tokens`), no cross-game minting (member_game excludes non-member/banned),
no blank/whitespace-token bypass, memoization doesn't re-query on nil, no
`skip_authorization`, XSS-safe (ERB escaping), DB+model uniqueness, correct purge. Two
optional low-severity notes, both **applied**:
- Case-insensitive `Bearer` scheme (RFC 7235) for third-party feed-reader interop — added
  `/i` to the header regex + a spec.
- One-line comment near `GamePolicy#feed?` documenting that the role-based GM branch is
  status-safe because a GM's membership status can't be changed.

### Verification (final)
- Full `bundle exec rspec`: green. Quality gate `--check`: all metrics within range
  (every changed file 100% line coverage). All 5 static gates green (authorization,
  policy-coverage, mutant-coverage, design-tokens, controller-ivars). Mutation coverage
  85.69% (floor 83.66%) on the pre-polish run; polish only added covered tests + a
  comment, re-run confirms it holds.
- Environment: `rbenv local` set by owner, so the pinned-Ruby gem mismatch from PR 1
  didn't recur.
