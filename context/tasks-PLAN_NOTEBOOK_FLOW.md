# Tasks: Notebook Flow Rework

Plan: `context/PLAN_NOTEBOOK_FLOW.md`
Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/71
PR: https://github.com/mrkplt/play-by-post/pull/222
Branch: `71-notebook-flow-rework`

**Execution note:** sequential, not parallel. Every phase converges on the same
files (Phase 0's `Config` is called by Phase 3; Phase 1's `ListEntryComponent` is
consumed by Phase 2; Phases 4–5 delete files Phase 2 must stop referencing first;
Phase 6 rewrites the specs for all of it). Dispatching subagents would produce
serialized handoffs plus conflicts on `notebook_form_component.html.erb`,
`.mutant.yml`, and the board component.

**Env:** prefix every Ruby command with `export PATH="$HOME/.rbenv/shims:$PATH"`
(3.3.6, not the shell default 4.0.2). `timeout` does not exist on this box.

Each task: implemented → tested → linted → committed → pushed, then checked off.

## Phase 0 — Migrate MarkdownEditorComponent heights to a vh scale

- [x] **0.1** Add `HEIGHTS = { sm: "20vh", md: "30vh", lg: "40vh", xl: "60vh" }` to
      `Ui::MarkdownEditorComponent::Config`. `edit_height:`/`preview_height:` take a
      Symbol key instead of Integer px; defaults `edit_height: :lg` (was 320),
      `preview_height: :md` (was 256). `edit_max_height`/`preview_max_height` emit
      `"max-height: #{HEIGHTS.fetch(key)}"`. Update the class comment that says
      heights are px.
- [x] **0.2** Convert the 7 affected template call sites to `:md`
      (feedback_modal, post_composer, post_edit_form, character_form, page_form,
      scene_resolve_form, scene_summary_form). `game_form` uses defaults only —
      unchanged. `notebook_card` is deleted in Phase 5.
- [x] **0.3** Update the 5 preview variants in
      `spec/components/previews/ui/markdown_editor_component_preview.rb` — `256` → `:md`.
- [x] **0.4** Update `markdown_editor_component_spec.rb` scroll-behaviour block —
      retarget the exact `max-height: Npx` assertions to vh values; add a case
      asserting an unknown symbol raises via `HEIGHTS.fetch`.
- [x] **0.5** Verify at both `ViewportHelper::VIEWPORTS` sizes that no editor
      collapses awkwardly on the short viewport. Measured in-browser: 30vh is
      243.6px on 375x812 (was 256px) and 270px on 1280x900.
- [x] **0.6** Commit + push Phase 0. → `f3e0826`

### Phase 0b — Region model (added mid-run; see Decisions)

- [x] **0b.1** Extract `Config` to `markdown_editor_component/config.rb` (the
      component was at 99 of the 100-line ceiling and `HEIGHTS` pushed it over).
- [x] **0b.2** Add `Region` interface (`placement`, `component`) plus
      `ToolbarRegion` and `PreviewRegion`.
- [x] **0b.3** Extract `Ui::MarkdownPreviewComponent` from the editor template's
      inline `content_tag`.
- [x] **0b.4** Replace Config's `toolbar:`/`preview:` booleans with a `regions:`
      collection; editor enumerates instead of branching. `preview_class` and
      `preview_height` move onto `PreviewRegion`; `rows` moves to the editor.
- [x] **0b.5** Add `Config.with_preview` for the toolbar-plus-preview surface
      that 8 of 9 call sites want.
- [x] **0b.6** Convert all 9 call sites; specs + previews for the new component;
      register 4 new classes in `.mutant.yml`.
- [x] **0b.7** Commit + push Phase 0b. → `8b806e6`

## Phase 1 — New shared primitives

- [x] **1.1** `Shared::ListEntryComponent` (`.rb` + `.html.erb`) — grouped-card
      layout only: card wrapper, `ROW_BASE`, `border-t border-card-divider` on every
      row but the first (lift from `game_pages_list_component.rb:33-42`). API:
      `rows:` = array of `{ title:, href:, controls: }` (controls = caller-built
      component instance or nil), plus `empty_text:`. Derived data, never a raw
      model. `# typed: strict`.
- [x] **1.2** `Shared::NotebookLaneSelectComponent` (`.rb` + `.html.erb`) — the lane
      `<select>`: `form_with` → `move_game_notebook_entry_path`,
      `onchange: "this.form.requestSubmit()"`, options from `NotebookEntry::STATUSES`
      (lift markup from `notebook_card_component.html.erb:37-41`, labels from
      `notebook_card_component.rb:15-20`). `# typed: strict`.
- [x] **1.3** Specs for both components.
- [x] **1.4** Lookbook previews for both components.
- [x] **1.5** Register both in `.mutant.yml` under `matcher.subjects`.
- [x] **1.6** Commit + push Phase 1. → `eff18f9`

## Phase 2 — Board becomes a title list

- [x] **2.1** Rewrite `NotebookBoardComponent` — rows from `entries_for(status)`:
      title → `edit_game_notebook_entry_path`, controls → `NotebookLaneSelectComponent`.
      Render `ListEntryComponent` per lane. Keep swimlanes + `<details>` discard
      disclosure. No body preview, no promoted link, no Edit/Promote/Delete.
- [x] **2.2** Recompose `GamePagesListComponent` onto `ListEntryComponent`; pages
      behavior unchanged (title → page, GM Edit/Delete injected). Delete its
      duplicated `ROW_BASE`/`row_classes`.
- [x] **2.3** Commit + push Phase 2. → `d336722`

## Phase 3 — Edit screen owns the controls

- [x] **3.1** GM action row on `edit.html.erb` — Delete (`turbo_confirm`), Promote
      (hidden once promoted; replaced by "Promoted to: …" link), Move
      (`NotebookLaneSelectComponent`). Save/Cancel stay in the `PageActionsComponent`
      footer.
- [x] **3.2** `notebook_form_component.html.erb` → `Config.new(edit_height: :xl,
      regions: [ Ui::MarkdownEditorComponent::ToolbarRegion.new ])` with
      `rows: 24` as an editor param. Under the Phase 0b region model, dropping the
      preview means omitting `PreviewRegion` — there is no `preview:` flag — which
      also carries away the `preview_class:` that used to be passed here.
- [x] **3.3** Commit + push Phase 3. → `6cf37bf`

## Phase 4 — Delete the show screen

- [x] **4.1** Routes — drop `:show` from `resources :notebook_entries`.
- [x] **4.2** Controller — delete `show`; drop from `set_notebook_entry`'s `only:`;
      delete `inline_request?` and its branches in `edit`/`update`; `update` success
      redirects to edit; `create` keeps its board redirect.
- [x] **4.3** Policy — delete `show?` and its spec block.
- [x] **4.4** Delete `show.html.erb`, `Shared::NotebookDetailComponent`
      (`.rb` + `.html.erb` + spec), and its `.mutant.yml` entry.
- [x] **4.5** `NotebookFormComponent#back_href` — Cancel goes to the board in both
      cases.
- [x] **4.6** Commit + push Phase 4. → `6cf37bf`

## Phase 5 — Remove inline-edit machinery

- [x] **5.1** Delete `Shared::NotebookCardComponent` — `.rb`, `.html.erb`, spec,
      preview, `.mutant.yml` entry.
- [x] **5.2** Delete turbo_stream views `edit.`, `update.`, `update_failed.`,
      `create.`; keep `create_failed.turbo_stream.erb`.
- [x] **5.3** Rewrite `move.turbo_stream.erb` — remove/append the new row markup
      instead of a card.
- [x] **5.4** Commit + push Phase 5. → `6cf37bf`

## Phase 6 — Tests

- [x] **6.1** Update `notebook_board_component_spec`, `game_pages_list_component_spec`,
      `notebook_form_component_spec`.
- [x] **6.2** Update `notebook_entries_controller_spec` — drop `show`; cover
      destroy/promote/move from edit; assert create→board and update→edit redirects.
- [x] **6.3** Update `campaign_notebook_spec` (system) — click title → edit; delete
      from edit; promote from edit; lane move on the board. Drop the show-screen
      promote example.
- [x] **6.4** Update `notebook_entry_policy_spec` — remove `show?`.
- [x] **6.5** Commit + push Phase 6. → `6cf37bf`

## Phase 7 — Docs and gates

- [x] **7.1** Amend `.claude/CLAUDE.md:434-436` — notebook entries are a deliberate
      no-preview exception (GM scratchpad, presentation deferred to promotion);
      `Config(preview: false)` supports it directly.
- [x] **7.2** Run gates: `bin/rubocop`, `bin/check-design-tokens`,
      `bin/check-mutant-coverage`, `bundle exec srb tc`, fast-tier rspec.
- [x] **7.3** Run `bin/full-check` (system specs + mutation + quality gate); lift
      any file below the coverage floor rather than dodging it.
- [x] **7.4** Commit + push Phase 7. → `6c5292e`

## Completion tail

- [x] **8.1** Independent evaluation agent — conformance to plan. Verdict:
      complete and conformant, all 8 phases delivered, every sentence of the
      card satisfied, no lingering references to deleted code, Pages behaviour
      byte-identical, 2315 examples / 0 failures. Two notes, both addressed
      below.
- [x] **8.2** Code review agent over this run's commits only. Two real defects found and fixed in `f31863c`; one low finding accepted. See below.
- [x] **8.3** Append `## Decisions` decision log to this file.

---

## Decisions

Judgment calls made during the run, in the order they came up.

### Execution shape

**Sequential, not parallel.** The plan's phases all converge on the same files
(Phase 0's `Config` is called by Phase 3; Phase 1's `ListEntryComponent` is
consumed by Phase 2; Phases 4–5 delete files Phase 2 must stop referencing).
Dispatching subagents would have produced serialized handoffs plus conflicts on
`notebook_form_component.html.erb`, `.mutant.yml`, and the board component.

**Phases 3–6 landed in one commit (`6cf37bf`).** Phase 3's new `move` branch
pushed `NotebookEntriesController` over the 100-line file-length ceiling, and
the deletions scheduled for Phases 4–5 were exactly what brought it back under.
Splitting them would have required a throwaway extraction to keep an
intermediate commit green.

### Deviations from the plan

**Phase 0b (region model) was added mid-run and was not in the plan.** The
plan's Phase 0 only migrated heights from px to a vh scale. Two things forced
more: (1) `markdown_editor_component.rb` was at 99 of a 100-line ceiling, so
`HEIGHTS` pushed it over and `Config` had to be extracted; (2) the extracted
file then tripped the ivar-hygiene ratchet, and the owner's direction was that
the guard had found a real design seam — `Config` was a data bag holding
`toolbar:`/`preview:` booleans about sub-components it did not own. Resolution:
regions are composed objects reporting their own placement, the editor
enumerates instead of branching, and the preview became a real component rather
than an inline `content_tag`. Ivar-hygiene violations went 7 → 0 as a
consequence, not as the goal.

**`Config.with_preview` was added.** After converting call sites to explicit
region lists, each one carried six lines of boilerplate to express the same
toolbar-plus-preview surface. The factory keeps the one varying thing (the
preview's classes) visible at the call site. Eight of nine call sites use it.

**`rows:` moved from `Config` to the editor.** It is a textarea attribute, not
layout configuration. This was the last remaining ivar-hygiene violation and
the fix was to put it where it belonged rather than wrap it.

**`Shared::NotebookLaneComponent` and `Shared::NotebookLaneUpdatesComponent`
were not in the plan.** Required by the move-response bug (below); a lane had
to become addressable and renderable outside the board.

**`Shared::PageRowActionsComponent` was not in the plan.** `ListEntryComponent`
takes a controls *component*, so the Pages list's GM Edit/Delete needed to be
one.

**A polling loop in a system spec was written and then removed.** Waiting on
`entry.reload.status` in a `Timeout.timeout` loop was a smell covering for a
real gap — the move gave no feedback at all off the board. Fixed the behaviour
(html branch redirects with a notice), then asserted on the observable outcome.

### Bugs found and fixed that the plan did not anticipate

**The lane `<select>` never worked outside the board.**
`form.requestSubmit()` is a no-op on a form with no submit button — per the
HTML spec. It only ever appeared to work because Turbo intercepts the board's
forms. Moving the same control to the edit screen exposed it. Fixed with an
sr-only submit button, verified in-browser by observing `submit` →
`turbo:submit-start` → `turbo:submit-end success=true`.

**A move left the entry visible in two lanes.** `move.turbo_stream.erb` removed
a row by `dom_id(@notebook_entry)` and appended a card. Once rows became shared
list markup with no per-entry id, the remove silently did nothing. Caught by the
system spec. The response now replaces the source and destination lanes whole,
which additionally keeps row dividers and empty-state placeholders correct —
something the append never handled.

**Flash notices do not survive a Turbo redirect on this screen.** Discovered
while asserting "Entry moved." after a lane move from the edit screen: the
write lands and Turbo follows the redirect, but the notice is not rendered. The
spec asserts the observable outcome (the select returns on the new lane)
instead. **Not fixed — pre-existing Turbo behaviour, unrelated to this card,
and worth its own ticket.**

### Guard interactions

Each guard that fired caught something real; none were worked around.

| Guard | Finding | Resolution |
|---|---|---|
| outdated gems | 8 > 5 threshold | `bundle update` (rack, sorbet ×4); 3 transitive majors remain, under threshold |
| file-length | editor 99 → 109 | Extracted `Config` to its own file |
| ivar-hygiene | 7 violations in extracted `Config` | 2 real V2s fixed; regions dissolved `toolbar`/`preview`; `rows` moved to the editor. 0 remaining |
| reek | `ControlParameter` on `regions: nil` | Real default value instead of a nil sentinel |
| reek | `ControlParameter` on `status == "discard"` | `EMPTY_TEXTS` lookup |
| reek | `BooleanParameter` on `turbo:` | Named `mode:` (`:board` / `:standalone`) with a `FORM_DATA` lookup |
| controller-ivar | +1 ivar on `move` | Derived affected lanes from `status_previously_was` instead of passing state. Two worse attempts (a component ivar, then stashing state on the model) were reverted |
| file-length | controller 115 → 121 | Pulled Phase 4/5 deletions forward |

### Deliberate non-changes

- **Lookbook previews remain unverified.** A spec to render them was written and
  removed: preview classes are not on the test autoload path and no existing
  preview is covered either. Building that infrastructure is outside this card.
  Filed as Fizzy **#86** (Guards and Quality), written toward removing Lookbook
  since the owner does not use the gallery. New previews were verified manually
  in the development environment.
- **Two `T.must`-stripping mutants left alive** in
  `NotebookLaneSelectComponent#status_options`. CLAUDE.md classes these as
  equivalent mutants, unkillable without contrived input; the aggregate is far
  above floor.
- **"Flash notices are lost on Turbo redirects" — this was my error, and it is
  retracted.** Mid-run I concluded from the edit-screen move that flash does
  not survive a Turbo redirect, worked around it in a spec, and filed Fizzy
  **#87**. Both were wrong. The real cause was review finding 1: that form
  never reached its redirect at all, because Turbo advertises a turbo-stream
  Accept header for every unsafe request and the controller returned lane
  streams targeting ids absent from the edit screen. No redirect ran, so no
  flash — the flash mechanism was never at fault. Verified in-browser after the
  fix across three redirect paths (move, update, promote): all three notices
  render. #87 has been commented with a retraction and should be closed.
  **Lesson: retest the premise after fixing an underlying bug instead of
  filing from the earlier observation.**

### Quality outcome

Baseline refreshed after a full run: mutation **83.66 → 91.92**, line **99.4 →
99.73**, branch **90.88 → 97.07**, sorbet **31.22 → 36.2**. The CSS figures move
much further than this branch does (view 823 → 193, component 237 → 936)
because the baseline was last saved in April and master has migrated markup into
components since — the save is a stale baseline catching up, not an effect of
this work.

### Evaluator findings and disposition

**"The checklist is stale (Phases 2–7 unchecked)."** — Already fixed; the agent
read a snapshot taken before the update. Verified: 45 items checked, only the
completion-tail items outstanding at the time of reading.

**"The baseline `--save` folds an unrelated months-old CSS correction into this
PR."** — Correct, and worth stating plainly. The evaluator independently
confirmed the CSS counts are identical on master and this branch (48 `class=`
occurrences either way), so the movement (view 823 → 193, component 237 → 936)
is a stale April baseline catching up to master's mobile-first redesign, not
anything this branch did.

Considered reverting just the CSS figures to master's values to keep the diff
narrow. **Rejected:** `css_in_components_pct` is a *floor* metric, so the stale
22.36% was permissive and the gate passed regardless — the save was never
needed to clear anything. Writing back a knowingly-false number to keep a diff
tidy would recreate exactly the staleness that caused the confusion. Kept the
true values and called it out in the commit message instead.

### Code review findings and disposition

**Finding 1 (HIGH) — `move` from the edit screen silently did nothing visible.
FIXED in `f31863c`.**
The `:standalone` mode omitted `data-turbo-stream` on the assumption that this
makes Turbo request HTML. It does not. Confirmed in the vendored source
(`vendor/javascript/@hotwired--turbo.js`):
`requestAcceptsTurboStreamResponse(e){return!e.isSafe||g("data-turbo-stream",…)}`
— every unsafe request advertises `text/vnd.turbo-stream.html`, so
`respond_to`'s `format.html` branch was unreachable. The edit screen received
two `replace` streams targeting `notebook_column_*` ids that do not exist
there, discarded both, and showed no confirmation. Browser-verified before and
after: `FLASH_PRESENT=false` → `true`.

The mode now travels as an explicit `response_mode` form field and the
controller branches on that. **This was my bug and my spec failed to catch
it**: the system spec asserted the select read "Expand" after the change, which
is true from the click alone regardless of whether the response is applied — it
passed against a screen where nothing visibly happened, and its comment
claiming otherwise was wrong. It now asserts the confirmation, and request
specs cover both response modes explicitly.

**Finding 2 (MEDIUM) — duplicate DOM ids across lane pickers. FIXED in
`f31863c`.** `form_with scope: :notebook_entry` gave every row
`id="notebook_entry_status"`, so all labels on a lane resolved to the first
row's select and a screen reader announced every row identically as "Lane".
Each select now carries a slug-scoped id with a matching `for`, and the label
names the entry ("Lane for <title>"). A lane-level spec asserts ids are
distinct and labels track them.

**Finding 3 (LOW) — `ListEntryComponent` emits `href` verbatim. NOT FIXED,
accepted.** Both call sites pass route-helper output, and the reviewer
confirmed `title:`/`empty_text:` are correctly escaped. Sanitizing a URL a
component does not own invites false confidence; the real guard is that callers
pass route helpers. Left as-is rather than adding defensive filtering to a
non-exploitable path.

Areas the reviewer checked and found clean: all 9 markdown-editor call sites
faithful across both migrations (no textarea gained or lost a cap), the region
abstraction, `NotebookLaneUpdatesComponent`'s dirty-state derivation, `move`
authorization (two independent layers), and every deletion (no dangling
references, no lost behaviour).
