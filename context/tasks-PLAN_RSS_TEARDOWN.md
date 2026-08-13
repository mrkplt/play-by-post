# Tasks — Plan 1: RSS teardown

Plan: `context/PLAN_RSS_TEARDOWN.md` · Branch `26-rss-teardown` · PR #216 · Fizzy #26

Executed as one coherent commit-group (all tasks touch overlapping files:
scene_summaries controller/specs/routes/docs), not parallelized.

## Checklist

- [ ] **T1 — Routes:** remove `generate_rss_token`/`revoke_rss_token`; move
  `scene_summaries` index inside `authenticate :user`; drop the RSS comment.
- [ ] **T2 — Controller:** `scene_summaries_controller.rb` — drop `skip_before_action`,
  add `:index` to `require_game_access!`, collapse `index` to HTML-only, delete
  `rss_access_allowed?`, keep `verify_authorized except: :index`.
- [ ] **T3 — Model/User:** delete `app/models/rss_token.rb`; remove `has_one :rss_token`
  from `user.rb`.
- [ ] **T4 — Migration:** `DropRssTokens` (reversible); update `db/schema.rb`.
- [ ] **T5 — RBI:** delete `sorbet/rbi/dsl/rss_token.rbi`; `tapioca dsl` reconcile.
- [ ] **T6 — Views/components:** delete `index.rss.builder`; remove RSS Feed button
  (keep footer); delete `Shared::RssTokenComponent` (.rb + .html.erb); remove profile
  RSS section.
- [ ] **T7 — Registration/checks:** `.mutant.yml` (drop RssToken +
  Shared::RssTokenComponent); `bin/check-authorization` allowlist entry;
  `docs/AUTHORIZATION.md`.
- [ ] **T8 — Specs:** delete rss_token model spec + factory; strip `.rss` describe +
  RSS button assertion in scene_summaries_spec; delete rss token describes in
  profiles_spec.
- [ ] **T9 — Verify:** `bin/pre-push` green; `grep -ri rss` clean (except innocuous
  settings_row placeholder); full rspec green.

## Decisions
(filled in at completion tail)
