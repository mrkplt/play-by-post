# Plan: Notebook Flow Rework

Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/71

## Goal

Notebook entries are GM scratchpad, not published content. The current
implementation treats them like mini-pages (rich kanban cards with body
previews, inline edit, a show screen). Collapse that: the board becomes a list
of titles in swimlanes, clicking a title goes straight to edit, and edit is
where every other control lives.

## Environment

`.ruby-version` pins 3.3.6; the default shell resolves to Homebrew Ruby 4.0.2.
rbenv has 3.3.6 installed and already selected by `.ruby-version` — only the
shims are off PATH. Prefix every Ruby/Rails/bundle command:

```bash
export PATH="$HOME/.rbenv/shims:$PATH"
```

Verified: `ruby -v` → 3.3.6, `bundle -v` → 4.0.9, fast tier 1459 examples /
0 failures. Note: `timeout` does not exist on this macOS box — do not wrap
commands in it.

## Decisions

| Question | Decision |
|---|---|
| Shared row component | Extract `Shared::ListEntryComponent`; controls injected as components by each caller |
| Post-create landing | Back to the notebook board |
| Promote | Edit screen only; redirect to the created page |
| Markdown preview | Use existing `Config(preview: false)`; amend CLAUDE.md |
| Editor heights | Migrate `Config` fully to a vh scale — convert all call sites, no px compatibility shim |

## Phase 0 — Migrate MarkdownEditorComponent heights to a vh scale

Full migration, not a compatibility shim: `Config` stops taking px integers.

- [ ] Add `HEIGHTS = { sm: "20vh", md: "30vh", lg: "40vh", xl: "60vh" }` to
      `Ui::MarkdownEditorComponent::Config` (`markdown_editor_component.rb:14-54`).
      `edit_height:`/`preview_height:` change from Integer px to a Symbol key;
      defaults `edit_height: :lg` (was 320px), `preview_height: :md` (was 256px).
      `edit_max_height`/`preview_max_height` (`:97-105`) emit
      `"max-height: #{HEIGHTS.fetch(key)}"` — no `px` interpolation. Update the
      class comment, which currently says heights are px values.
- [ ] Convert all template call sites to scale symbols:
      - `feedback_modal_component.html.erb:19` — `edit_height: 256` → `:md`
      - `post_composer_component.html.erb:19` — `preview_height: 256` → `:md`
      - `post_edit_form_component.html.erb:6` — `preview_height: 256` → `:md`
      - `character_form_component.html.erb:28` — `preview_height: 256` → `:md`
      - `page_form_component.html.erb:20` — `preview_height: 256` → `:md`
      - `scene_resolve_form_component.html.erb:6` — `preview_height: 256` → `:md`
      - `scene_summary_form_component.html.erb:20` — `preview_height: 256` → `:md`
      - `notebook_card_component.html.erb:10` — deleted in Phase 5
      - `game_form_component.html.erb:20` — defaults only, unchanged
- [ ] Update the 5 preview variants
      (`spec/components/previews/ui/markdown_editor_component_preview.rb:10,16,22`)
      — `256` → `:md`.
- [ ] Update `markdown_editor_component_spec.rb` — the scroll-behaviour block
      (`:24-52`) asserts exact `max-height: 320px` / `180px` / `120px` strings;
      retarget to the vh values. Add a case asserting an unknown symbol raises
      (`HEIGHTS.fetch`) so the scale cannot be bypassed silently.
- [ ] Verify visually at both `ViewportHelper::VIEWPORTS` sizes — 30vh is ~244px
      on 812px mobile (close to today's 256px), ~270px on 1280×900 desktop.
      Confirm no editor collapses awkwardly on the short viewport.

## Phase 1 — New shared primitives

- [ ] `Shared::ListEntryComponent` — `app/components/shared/list_entry_component.{rb,html.erb}`.
      Owns grouped-card layout only: card wrapper, `ROW_BASE` row classes,
      `border-t border-card-divider` on every row but the first (lift from
      `game_pages_list_component.rb:33-42`). API: `rows:` — array of
      `{ title:, href:, controls: }` where `controls` is a caller-built component
      instance or nil; plus `empty_text:`. Derived data, never a raw model.
      `# typed: strict`.
- [ ] `Shared::NotebookLaneSelectComponent` —
      `app/components/shared/notebook_lane_select_component.{rb,html.erb}`.
      The lane `<select>`: `form_with` → `move_game_notebook_entry_path`,
      `onchange: "this.form.requestSubmit()"`, options from
      `NotebookEntry::STATUSES` (lift from `notebook_card_component.html.erb:37-41`
      plus `STATUS_LABELS` at `notebook_card_component.rb:15-20`). Used on both
      board rows and the edit screen. `# typed: strict`.
- [ ] Specs + Lookbook previews for both.
- [ ] Register both in `.mutant.yml` under `matcher.subjects`.

## Phase 2 — Board becomes a title list

- [ ] Rewrite `NotebookBoardComponent` — build row hashes from
      `entries_for(status)`: title → `edit_game_notebook_entry_path`, controls →
      `NotebookLaneSelectComponent`. Render `ListEntryComponent` per lane. Keep
      swimlanes + `<details>` discard disclosure. No body preview, no promoted
      link, no Edit/Promote/Delete.
- [ ] Recompose `GamePagesListComponent` onto `ListEntryComponent` — pages
      behavior unchanged (title → page, GM Edit/Delete as injected controls).
      Delete its now-duplicated `ROW_BASE`/`row_classes`.

## Phase 3 — Edit screen owns the controls

- [ ] GM action row on `edit.html.erb` — Delete (`turbo_confirm`), Promote
      (hidden once promoted; replaced by "Promoted to: …" link), Move
      (`NotebookLaneSelectComponent`). Save/Cancel stay in the
      `PageActionsComponent` footer. Mirrors
      `notebook_detail_component.html.erb:2-16`, which is being deleted.
- [ ] Enlarge the markdown box, drop the preview —
      `notebook_form_component.html.erb:19-24` →
      `Config.new(scroll: :edit, edit_height: :xl, rows: 24, preview: false)`.
      Uses the Phase 0 scale (`:xl` = 60vh) so the height goes through `Config`
      like every other editor. Drop the now-unused `preview_class:` arg; toolbar
      stays.

## Phase 4 — Delete the show screen

- [ ] Routes — drop `:show` from `resources :notebook_entries`
      (`config/routes.rb:69`).
- [ ] Controller (`notebook_entries_controller.rb`) — delete `show`; drop it from
      `set_notebook_entry`'s `only:`; delete `inline_request?` and its branches in
      `edit`/`update`; `update` success redirects to edit; `create` keeps its
      board redirect.
- [ ] Policy — delete `show?` (`notebook_entry_policy.rb:15-18`) and its spec block.
- [ ] Delete `app/views/notebook_entries/show.html.erb`,
      `Shared::NotebookDetailComponent` (`.rb` + `.html.erb` + spec), and its
      `.mutant.yml` entry.
- [ ] `NotebookFormComponent#back_href` (`:34`) — no show screen to return to;
      Cancel goes to the board in both cases.

## Phase 5 — Remove inline-edit machinery

- [ ] Delete `Shared::NotebookCardComponent` — `.rb`, `.html.erb`, spec, preview,
      `.mutant.yml` entry.
- [ ] Delete turbo_stream views — `edit.`, `update.`, `update_failed.`, `create.`.
      Keep `create_failed.turbo_stream.erb` (targets the form, not a card).
- [ ] Rewrite `move.turbo_stream.erb` — remove/append the new row markup instead
      of a card; lane moves stay live Turbo on the board.

## Phase 6 — Tests

- [ ] Update component specs — `notebook_board_component_spec`,
      `game_pages_list_component_spec`, `notebook_form_component_spec`.
- [ ] Update `notebook_entries_controller_spec` — drop `show`; cover
      destroy/promote/move reached from edit; assert create→board and update→edit
      redirects.
- [ ] Update `campaign_notebook_spec` (system) — click title → edit; delete from
      edit; promote from edit; lane move on the board. Drop the show-screen
      promote example (`:75-84`).
- [ ] Update `notebook_entry_policy_spec` — remove `show?`.

## Phase 7 — Docs and gates

- [ ] Amend CLAUDE.md `.claude/CLAUDE.md:434-436` — name notebook entries as a
      deliberate no-preview exception (GM scratchpad, presentation deferred to
      promotion), noting `Config(preview: false)` supports it directly.
- [ ] Run the gates — `bin/rubocop`, `bin/check-design-tokens`,
      `bin/check-mutant-coverage`, `bundle exec srb tc`, fast-tier rspec, then
      `bin/full-check` before the PR. Watch: `# typed: strict` on new components,
      ≥80% line / ≥70% branch on every touched file, no ternary/`||` in ERB output
      tags, no raw hex.

## Notes

- **Blast radius:** Phase 0 pulls 8 form components into the branch's changed-file
  set, so the gate evaluates coverage and mutation for all of them — including
  pre-existing gaps. Per CLAUDE.md that is intended; lift anything below the floor
  rather than dodge it.
- **Consequence of deleting show:** after this change a GM never sees their
  notebook body rendered — only the raw textarea — until promotion to a Page.
  That is what card #71 specifies.
