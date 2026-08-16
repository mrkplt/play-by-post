# Tasks — Draftable (#100), Versionable (#101), Templates (#94)

Source of truth: `plan-draftable-versionable-templates.md`.
Owner decisions settled: draft is a boolean on the row; editing published never
pulls published text away (no shadow copy); #101 uses per-model version tables;
#94 covers page/note/character.

These cards are **not independent** — #100, #101, #94 all touch Page and
SceneSummary. Run **sequentially**, one commit per task, pushed before checking
the box.

## Card #100 — Draftable

- [x] 100.1 Migrations: add `draft` boolean (default false, null false) to
      `pages` and `scene_summaries`; update schema. (2eb38ca)
- [x] 100.2 `Draftable::Model` plain module: `draft?`/`published?`/`publish!`
      instance behaviour, included (not a concern). Scopes + presence-unless-draft
      stay declared on each model (visible, typed). Post refactored onto it,
      keeping its `user_id` uniqueness rule. Mutation 93.33% (3 equivalent
      mutants). (a8c283f)
- [x] 100.3 `Draftable::Presentation` module: `draft?`, `draft_status_label`,
      `hidden_from_players?`. Included in Post/Page/SceneSummary presenters.
      Mutation 94.33% (equivalent survivors). (fa62de4)
- [x] 100.4 Renamed `post_draft_controller.js` → `draft_controller.js`,
      parameterized `publishLabel` + `paramKey`; rewired Post composer; deleted
      old file. Draft posts system spec green. (5466c26)
- [x] 100.5 Reshaped `DraftRecoveryComponent` to be record-agnostic (takes
      draft presenter + discard_path + notice, dropping game/scene presenters;
      100% mutation). Render site thinned via `ScenePostsPresenter#draft_discard_path`
      + `DRAFT_RECOVERY_NOTICE`. `Draftable::Component` as a single shared
      ViewComponent deferred to composer build (100.6/100.7), where the real
      composer duplication becomes visible — avoids speculative abstraction. (ec2fe76)
**Owner decision (draft UX — FINAL):** one consistent pattern across all three,
cleanest/most robust. Each draftable record gets its OWN namespaced drafts
controller (`Posts::DraftsController` already; add `Pages::DraftsController`,
`SceneSummaries::DraftsController`) doing live autosave, reusing
`draft_controller.js`. A generic/shared drafts controller is what was rejected —
namespaced-under-the-record is legitimate.

Storage differs where the models genuinely differ (a hard constraint, not a
preference):
- **Post** — `scene_summaries`-style uniqueness does NOT apply; a draft is a
  distinct row per `(user, scene)` via `PostDraft`. Unchanged.
- **SceneSummary** — `scene_id` is UNIQUE, so it physically cannot hold a
  separate draft row beside a published one. Its drafts controller autosaves the
  `draft` boolean ON the single row.
- **Page** — one row; drafts controller autosaves the `draft` boolean on it.

Same controller seam, same JS, same UX; storage matches each model's schema.

- [x] 100.6 Page drafting: `published` scope on member-facing index (GM sees
      drafts, players don't). (0042782)
**Owner refinement:** extract a shared `Draftable::Controller` module for the
common draft-controller machinery (the fourth Draftable layer, alongside Model /
Presentation). It captures what the BOOLEAN-ON-ROW adopters share — `save`
(update record `draft: true`, JSON) and `publish` (`publish!` + redirect),
parameterized by record lookup / permitted params / param key / redirect. Post
is NOT forced into it: Post's draft is a separate row via `PostDraft` (distinct
mechanics — service-backed, discard-not-publish, id-not-slug), which genuinely
does not generalize. Page and SceneSummary include the module.

- [x] 100.6b `Draftable::Controller` extracted (draftable_save/draftable_publish
      helpers; thin delegating actions per adopter). `Pages::DraftsController`
      adopts it: autosave draft flag + publish on the page row; form wired to
      `draft_controller.js`; Draft badge + Publish affordance;
      `PageRoutesPresenter` extracted. Both subjects ~86% mutation. Key learning:
      mutant keys test selection to the described constant, so the shared module
      needs a spec that `describe`s it. (c7b01f0)
- [x] 100.7 `SceneSummaries::DraftsController` adopts `Draftable::Controller`;
      model draftable; form autosave + toggle; display Draft badge + Publish;
      SceneSummaryRoutesPresenter draft/publish paths. ~90%+ mutation. (6196042)
- [x] 100.8 **Read-path audit — SceneSummary (5 leak points):** (6ce0d40)
      (1) `public_for_game` now starts from `.published` — DONE;
      (2) RssController inherits the fix + live-feed spec — VERIFIED;
      (3) SceneSummariesController#index inherits — VERIFIED;
      (4) `SceneShowBuilder#summary_presenter` gates the has_one (GM sees own
          draft, player gets nil) — DONE, gate manually verified;
      (5) `ScenePageAction` "Write summary" is GM-only and treats any existing
          summary as "already started" — no change needed, documented.
- [x] 100.9 Tests: model scopes/validations/publish! per adopter; read-path
      specs (public_for_game + live RSS + scene-show gate); request specs for
      the drafts controllers; system specs (both viewports) Page + SceneSummary
      draft→publish + player-hidden invariants. (d062449)
- [x] 100.10 All new modules/components/presenters in `.mutant.yml`; `srb tc`
      clean; guards clean throughout (concerns, callbacks, view-layering,
      design-tokens, ivar-hygiene, reek, mutant-coverage). Full unit suite:
      2842 examples green, 99.86% line coverage.

**CARD #100 (Draftable) COMPLETE.**

## Card #101 — Versionable (per-model tables)

- [x] 101.1 `Versionable::Model` plain module: transaction-wrapped save/save!
      snapshot, adopter declares `versions` + `version_attributes`. No callback.
      ~88% mutation. (eaf29ef)
- [x] 101.2 Character extracted onto it — behaviour identical (rollback,
      touch/update_column bypass), verified. (eaf29ef)
- [x] 101.3 Page versioning: `page_versions` table (`title`, `body`,
      `edited_by_id`); Page adopts Versionable::Model snapshotting title+body.
      Attribution is Current.user (owner decision — matters for future
      edit-control policy); factory sets an editor, suite resets Current.
      GamePurgeScope deletes page_versions before pages. (7f1871e)
- [x] 101.4 PageVersionsController + PageVersionPolicy + PageVersionPresenter +
      PageVersionHistoryComponent + show route/view, mirroring the Character
      stack. GM-only history on the page show. (5af9498)
- [x] 101.5 Tests: snapshot on save/save! not touch/update_column, rollback on
      failed snapshot (Versionable::Model spec via Character); Page versioning +
      view-stack specs; purge cleanup. (7f1871e, 5af9498)
- [x] 101.6 `tapioca` RBIs; all new subjects in `.mutant.yml`; `srb tc` + every
      guard clean (policy-coverage, controller-ivars, reek, etc.). Full unit
      suite 2873 green.

**CARD #101 (Versionable) COMPLETE.**

## Card #94 — Templates

**Owner decision (revised from card):** templates are NOT a boolean on content
rows — separate storage, fully orthogonal to draft/version, no leakage. A
template is config, not content, so it never appears in a member-facing list, is
never version-snapshotted, and is never draftable.

- [x] 94.1 `content_templates` table (`game_id`, `content_type`, `body`,
      timestamps) — named for the `ContentTemplate` model rather than the plan's
      `game_templates`; same columns + unique index on (game_id, content_type).
      content_type ∈ {page, note, character}. (fa726cd)
- [x] 94.2 New-record forms for page/note/character seed body from the template
      row when one exists (blank when absent), via `ContentTemplate.body_for`.
      (fa726cd)
- [x] 94.3 ContentTemplatesController (GM-only CRUD) + TemplateFormComponent
      (markdown body, content-type select) + list component; linked from game
      settings. (2f65a0c, 85260d1)
- [x] 94.4 Tests: uniqueness per (game, content_type); form pre-fill
      present/absent (page/note/character); system spec (both viewports) set
      template → create pre-filled page. (fa726cd, 85260d1)
- [x] 94.5 All subjects in `.mutant.yml`; `srb tc` + guards clean.

**CARD #94 (Templates) COMPLETE.**

---

## All three cards complete. Completion tail below.

## Decisions

Judgment calls and deviations made during the run (owner-confirmed ones marked ✓):

- **Draft = boolean on row; editing published never removes published text ✓** —
  settled up front. No shadow copy / separate draft row for Page/SceneSummary.
- **Draftable::Model shape changed from the plan** — the plan described a
  class-macro installing scopes+validations. That was un-typeable (`typed: false`
  fails the sigil gate) and un-mutation-testable (a load-time macro can't be
  killed by mutant). Redesigned to an instance-behaviour module
  (`draft?`/`published?`/`publish!`), with scopes + presence-unless-draft
  declared on each model. Owner endorsed ("the gates enforce good practices").
- **Namespaced drafts controller per record ✓** — a generic/shared drafts
  controller was rejected; `Pages::DraftsController` /
  `SceneSummaries::DraftsController` each adopt `Draftable::Controller`. Post
  keeps its distinct-draft-row `PostDraft` mechanics (they don't generalize).
- **Draftable::Controller: helpers, not actions** — mutant cannot kill mutations
  in a Rails *action* method inserted via a module (its undef/reinsert cycle
  doesn't round-trip through `include`). Root cause found by reading mutant's
  source: `mutant/subject/method/instance.rb`. Fix: the module exposes
  `draftable_save`/`draftable_publish` helpers; each controller's thin action
  delegates. Also learned mutant keys test selection to the *described*
  constant, so shared modules need a spec that `describe`s them.
- **SceneSummary must be boolean-on-row** — `scene_summaries.scene_id` is UNIQUE,
  so it physically cannot hold a separate draft row. This is what forced the
  shared boolean-on-row pattern (Post's separate-row model is the exception).
- **Read-path leak #5 (ScenePageAction "Write summary")** — left unchanged: the
  branch is GM-only and treating any existing summary (draft or not) as "already
  started" is correct; not a leak.
- **#101 per-model version tables ✓; Page attribution is Current.user ✓** — a
  page has no owning user; owner confirmed attribution matters for a future
  edit-control policy. Consequence: page saves need Current.user, so the page
  factory sets an editor, the suite resets Current after each example, and
  `NotebookEntryPromotion`/draftable specs set it explicitly.
- **#94 separate ContentTemplate storage ✓** — not a boolean on content rows;
  keeps templates orthogonal to draft/version (never lists, versions, drafts).
- **Presenter/controller extractions to satisfy gates** — `PageRoutesPresenter`
  (reek TooManyMethods), `GamePurgeScope#delete_pages_and_versions` +
  `page_ids` locals (reek DuplicateMethodCall/FeatureEnvy/TooManyStatements/
  TooManyInstanceVariables). Ivar-hygiene fixes on page/template form components.
- **Gem maintenance** — only 3 updatable gems (< 5 threshold); no `bundle update`
  required.
### Completion-tail agent findings & dispositions

**Independent evaluator** — verdict: all three cards **conform** to the plan and
all four owner decisions; gates green (srb clean, 2923 rspec examples pass).
Minor notes, all handled:
- `content_templates` vs plan's `game_templates` table name — deliberate (matches
  the `ContentTemplate` model); same columns + unique index. Doc updated.
- Stale 94.1/94.2 checkboxes — fixed (were implemented, checkboxes lagged).
- "GM-only history" note on 101.4 was inaccurate — PageVersion history follows
  game access (mirrors CharacterVersion), as the plan directed. See below re the
  draft case, which the code review caught.

**Code review** — two HIGH draft-leak findings, both CONFIRMED against the code
and FIXED (I had closed the SceneSummary record-level read paths but not Page's):
- **HIGH — draft Page leaked via `pages#show`** (`PagePolicy#show?` returned
  `viewable?` with no draft check). FIXED: `show?` now returns `manage?` for a
  draft page. Denial test added (`pages_spec.rb`), policy 100% mutation.
- **HIGH — draft Page content leaked via `page_versions#show`** (every draft
  autosave snapshots a version; `PageVersionPolicy#show?` granted any member).
  FIXED: a version of a draft page is manager-only. Denial test added
  (`page_versions_spec.rb`), policy 100% mutation.
- **MEDIUM — Page version attribution NOT-NULL trap** (`Current.user&.id` with no
  fallback, `edited_by` is null:false). ACCEPTED per owner decision (pages must
  have a current-user editor; guarded by factory + the fact that every live save
  is in a request). Recorded as a known hard coupling — no `|| user_id` fallback
  exists the way Character has, so the first non-request Page save would raise
  and roll back. Revisit if a background/rake path ever creates a Page.
- **LOW — every draft autosave writes a page_version** (version-history noise).
  ACCEPTED: inherent to "every save is a version"; the leak vector it enabled is
  now closed by the version-endpoint draft gate. Page draft autosave is
  on-submit, not per-keystroke, so the volume is bounded.
- **LOW — `SceneSummaries::DraftsController#draftable_record` `T.must` 500s if no
  summary exists.** NO CHANGE: unreachable via the UI (a summary is created
  before it can be drafted); adding a guard for a raw-request-only path is the
  just-in-case defensive code CLAUDE.md bans. `T.must` is the honest assertion.
- Areas the review confirmed clean: SceneSummary draft read paths (log/RSS/scene
  show), draft-controller GM gating, ContentTemplatesController authz + unique
  index, GamePurgeScope FK-safe delete order, module boundaries.

## Completion tail

- [ ] Independent evaluator agent (did not implement) confirms conformance.
- [ ] Code-review agent over this run's commits only; dispositions recorded.
- [ ] `## Decisions` section appended below.
