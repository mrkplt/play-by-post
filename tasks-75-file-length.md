# Tasks: Flat 100-line file ceiling (#75)

Plan: `plan-75-file-length.md` · Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/75
PR: https://github.com/mrkplt/play-by-post/pull/234

Baseline before any change: 2773 examples, 0 failures, line 99.82% / branch 97.18%.

Each task: implement → rspec → ts-standard/rubocop → srb tc → commit → push.
Splits land before the gate flip so the suite is never red mid-branch.

## Splits

- [x] **1. `game_export_service` (403 → 44).** Extract the pure
      `(model) -> String` formatters into their own units; leave an orchestrator
      owning zip assembly, the policy gate, and the reads. Move the matching
      spec sections with the code (specs currently reach the formatters via
      `service.send(:readme_content, …)`, so those call sites move too).
- [x] **2. `scenes_controller` (184 → under 100).** Extract the presenter-assembly
      cluster (`build_scene_show_presenter`, `build_scene_posts_presenter`,
      `build_post_presenters`, `build_scene_summary_presenter`) following the
      existing `PostPresenterBuilder` / `SceneFormBuilder` pattern. `build_tree`
      goes with the tree-building concern.
- [x] **3. `games_controller` (155 → under 100).** Extract the dashboard-query slice
      (`dashboard_memberships`, `policy_by_game_id`, `games_with_new_activity`).
      Collapse the three near-identical toggle actions if it does not obscure
      the distinct redirect targets and flash copy.
- [x] **4. `posts_controller` (113 → under 100).** Extract the draft lifecycle
      (`draft_or_new_post`, `update_draft_attributes`, `new_post_from_params`).
- [x] **5. `notebook_entries_controller` (102 → under 100).** 2 lines over; smallest
      extraction that still leaves a coherent unit.

## Gate

- [x] **6. Flip `bin/check-file-length` to a flat ceiling.**
      - fail on `new_count > LIMIT` regardless of delta
      - sweep all `app/` + `lib/` Ruby files, not just those changed vs `origin/master`
      - drop grandfathering from the header comment and the remedy text
      - confirm it fails loudly if any file is over, and passes on this branch

## Cross-cutting (verify before the run is done)

- [x] **7.** Every new class registered in `.mutant.yml`
- [x] **8.** `# typed: true` (or stricter) on every new file; `bundle exec srb tc` clean
- [ ] **9.** `bin/full-check` green; final commit and push

## Decisions

_(appended at the end of the run)_
