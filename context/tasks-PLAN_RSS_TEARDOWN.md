# Tasks — Plan 1: RSS teardown

Plan: `context/PLAN_RSS_TEARDOWN.md` · Branch `26-rss-teardown` · PR #216 · Fizzy #26

Executed as one coherent commit-group (all tasks touch overlapping files:
scene_summaries controller/specs/routes/docs), not parallelized.

## Checklist

- [x] **T1 — Routes:** removed `generate_rss_token`/`revoke_rss_token`; moved
  `scene_summaries` index inside `authenticate :user`; dropped the RSS comment.
- [x] **T2 — Controller:** `scene_summaries_controller.rb` — dropped `skip_before_action`,
  added `:index` to `require_game_access!`, collapsed `index` to HTML-only, deleted
  `rss_access_allowed?`, kept `verify_authorized except: :index`.
- [x] **T3 — Model/User:** deleted `app/models/rss_token.rb`; removed `has_one :rss_token`
  from `user.rb`. Also removed the dead `generate/revoke_rss_token` actions from
  `ProfilesController`.
- [x] **T4 — Migration:** `DropRssTokens` (reversible); `db/schema.rb` updated.
- [x] **T5 — RBI:** deleted `sorbet/rbi/dsl/rss_token.rbi`; `tapioca dsl User`
  regenerated `user.rbi` (no unrelated RBI disturbed).
- [x] **T6 — Views/components:** deleted `index.rss.builder`; removed RSS Feed button
  (footer kept, GM-only cancel inside); deleted `Shared::RssTokenComponent` (.rb +
  .html.erb) + its spec; removed profile RSS section.
- [x] **T7 — Registration/checks:** `.mutant.yml` (dropped RssToken +
  Shared::RssTokenComponent); `bin/check-authorization` entry removed;
  `docs/AUTHORIZATION.md` line refs + table updated; two stale RSS comments in
  policies updated.
- [x] **T8 — Specs:** deleted rss_token model spec + factory + component spec; stripped
  `.rss` describe + RSS button assertion; reconciled banned/non-member redirect to
  `root_path`; deleted rss token describes in profiles_spec.
- [x] **T9 — Verify:** full `bundle exec rspec` green (2186 ex, 0 fail); `bin/pre-push`
  green (1422 ex); `bin/quality-metrics --check` all green; static gates
  (authorization/design-tokens/mutant-coverage) green; `grep -ri rss` clean except the
  innocuous settings_row placeholder + historical migrations.

## Decisions

### Deviations from the plan (intentional)
- **Removed dead `generate/revoke_rss_token` actions from `ProfilesController`.** The plan
  removed their routes; leaving the actions would be dead code, so they went too.
- **Removed `spec/components/shared/rss_token_component_spec.rb`.** Not in the plan's
  explicit delete list, but the component it tests was deleted, so the spec had to go.
- **Cleaned two stale RSS comments** in `scene_summary_policy.rb` and
  `user_profile_policy.rb`. In-spirit, harmless.
- **Behavior change — banned/non-member signed-in redirect target.** The old inline HTML
  guard sent everyone to `new_user_session_path`. The collapsed `index` now uses the
  standard `require_game_access!` guard, which redirects a signed-in-but-unauthorized user
  to `root_path` (matching how `new`/`create`/etc. already behave). Two specs updated to
  assert `root_path`. Unauthenticated users still hit Devise → sign-in. This is the
  consistent, intended behavior, fully covered by specs.

### Footer / layout (owner constraint)
- Per the owner ("keep layouts consistent, an empty footer is ok, the previous run removed
  too many shared elements"): kept the campaign-log `PageActionsComponent` footer; removed
  only the RSS Feed button. Footer always renders; GM-only "Edit Game" cancel stays inside.
  An empty primary for a player is the endorsed consistent state.

### Evaluator findings (independent agent) and dispositions
- **GAP: `bin/check-policy-coverage:28` still listed `RssToken`** in `NON_AUTHORIZABLE`.
  The plan's grep scope (`app lib config db spec`) excluded `bin/`, so it was missed.
  **FIXED** — removed the entry; `bin/check-policy-coverage` passes; `bin/` now grep-clean.
- All other plan tasks verified conformant against the diff.

### Code-review findings (independent agent) and dispositions
- **No correctness/security/maintainability defects introduced.** Verified: index collapse
  correct, migration reversible, no orphaned references, route helper identical, views
  clean, spec redirect expectations correct against `GamePolicy#show?`/`Game#viewable_by?`.
- **Non-blocking note:** `context/` planning docs committed on the branch. **Kept** — this
  repo tracks `context/` (existing files there), and both plans living together is useful.
  No action.

### Environment note (not a code issue)
- Push hook first failed with `simplecov-1.1.1` missing: gems had been installed under
  Homebrew Ruby 4.0.2 while the project pins rbenv 3.3.6. Fixed by `bundle install` under
  3.3.6; owner then set `rbenv local`. `Gemfile.lock` unchanged.
- SimpleCov `add_filter`/`add_group` deprecation warnings surface on rspec runs — pre-existing
  gem drift, unrelated to this change, not addressed here.
