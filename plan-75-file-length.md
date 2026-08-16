# Plan: Flat 100-line file ceiling

Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/75

## Goal

Split the five `app/` files still over 100 code lines, then change
`bin/check-file-length` from a ratchet into a flat, unconditional ceiling: no Ruby
file in `app/` or `lib/` may exceed 100 code lines, whether or not the branch
touched it.

## Current state

227 Ruby files in `app/` + `lib/`; 5 over the ceiling. The card names 14
grandfathered files, but 9 of those have already dropped under 100 through other
work (characters_controller, markdown_editor_component, scene_presenter,
scene_summaries_controller, button_component, scene_form_component,
scene_summary_service, game, resend/inbound_emails_controller).

| Code lines | File |
|---|---|
| 403 | `app/services/game_export_service.rb` |
| 184 | `app/controllers/scenes_controller.rb` |
| 155 | `app/controllers/games_controller.rb` |
| 113 | `app/controllers/posts_controller.rb` |
| 102 | `app/controllers/notebook_entries_controller.rb` |

## Tasks

- [ ] `game_export_service` (403) — extract the content formatters. They are pure
      `(model) -> String` with no zip dependency: readme, files manifest, links
      manifest, scene info, posts, character sheet/version, page, notebook entry.
      Leave a thin orchestrator owning archive assembly and slug/byte helpers.
- [ ] `scenes_controller` (184) — extract the presenter-assembly cluster
      (`build_scene_show_presenter`, `build_scene_posts_presenter`,
      `build_post_presenters`, `build_scene_summary_presenter`, `build_tree`).
- [ ] `games_controller` (155) — extract the dashboard-query slice
      (`dashboard_memberships`, `policy_by_game_id`, `games_with_new_activity`);
      collapse the three near-identical toggle actions.
- [ ] `posts_controller` (113) — extract the draft lifecycle
      (`draft_or_new_post`, `update_draft_attributes`, `new_post_from_params`).
- [ ] `notebook_entries_controller` (102) — 2 lines over; smallest extraction that
      leaves a coherent unit.
- [ ] Flip the gate (last, so the suite is never red mid-branch):
      - fail on `new_count > LIMIT` regardless of delta
      - sweep all of `app/` + `lib/`, not just files changed vs `origin/master`
      - drop the grandfathering language from the header comment and remedy text
- [ ] Register any new components/presenters in `.mutant.yml`
- [ ] `# typed: true` sigil on every new file; `bundle exec srb tc` clean
- [ ] Full check green, then commit and push

## Notes

- Sequencing matters: splits land before the gate flip, in the same PR. Flipping
  first turns the suite red until the splits are done.
- One PR, per owner direction.
- Export-service specs pin generated file contents, so the formatter extraction
  is covered by the existing suite.
