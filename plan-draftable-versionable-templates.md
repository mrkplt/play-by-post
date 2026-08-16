# Plan — Draftable (#100), Versionable (#101), Templates (#94)

Three Fizzy cards that touch the same model surfaces (Post, Page, SceneSummary,
Character). Worked as one branch because they collide on Page and SceneSummary.

## Load-bearing decision (owner, settled)

**Draft is a boolean on the row. Editing a published record never pulls the
published text away from anything** — the live version stays live in the
campaign log and RSS while the author edits. No shadow copy, no separate draft
row for Page/SceneSummary.

Consequences:
- `Draftable::Model` is exactly Post's existing shape (a `draft` boolean +
  scopes + presence-unless-draft). No shadow-copy mechanism.
- `draft` only ever guards a record that has **never** been published. Once
  published, edits are always live (matches Post today).
- Versionable stays a genuinely separate concern: drafting holds no prior copy,
  so versioning is the only thing recording "what it was."
- Templates is its own boolean, orthogonal to `draft`.

## Conventions that constrain the shape (from CLAUDE.md + code)

- **No `ActiveSupport::Concern`, no `app/**/concerns/`** — `bin/check-concerns`
  enforces. Modules are plain `module`s with `abstract!`, mixed in with
  `include`, following `Shared::RecordBackedForm`.
- **No `after_save` callback for versioning** — `bin/check-callbacks` ratchets
  callbacks *down*. Character overrides `save`/`save!` inside a transaction and
  keeps `version_attributes` pure. Any Versionable module must preserve this.
- Sorbet `# typed: true` on every touched file; explicit `sig` on anything a
  ViewComponent template calls. Regenerate RBIs with `bundle exec tapioca` if
  new tables/models appear.
- Every new component/presenter goes in `.mutant.yml`.
- Markdown fields get toolbar + preview (all three content bodies already are).

---

## Card #100 — Draftable: extract drafting for Post, Page, SceneSummary

Scope: **Post** (source), **Page** (new), **SceneSummary** (new).
Excluded: NotebookEntry (GM is sole reader), Character (versionable not draftable).

### Three modules (plain modules, `abstract!`)

- **`Draftable::Model`** — `published`/`drafts` scopes, presence-unless-draft
  validation, `publish!`. NOT the uniqueness rule (Post's one-per-(user,scene)
  does not generalize; SceneSummary already has one-per-scene in schema).
  Requires a `draft` boolean column on the adopter.
- **`Draftable::Presentation`** — `draft?`, status label, the "not visible to
  players yet" affordance. New for Page and SceneSummary.
- **`Draftable::Component`** — the generalized autosave wiring
  (controller binding, targets, save URL, status span, toggle) + the
  generalized Stimulus controller.

### Migrations

- `add_column :pages, :draft, :boolean, default: false, null: false`
- `add_column :scene_summaries, :draft, :boolean, default: false, null: false`

### Refactor Post onto the modules

- Move `published`/`drafts` scopes + presence-unless-draft into `Draftable::Model`.
- Keep Post's `validates :user_id, uniqueness:` in Post — it does not generalize.

### Generalize the Stimulus controller

`post_draft_controller.js` is ~70 lines, only two post-specific:
- `submit.value = "Post"` (line 32) → a value (`publishLabel`).
- `body: JSON.stringify({ post: { content } })` (line 58) → parameterize the
  wrapper key (`paramKey` value) so it emits `{ page: { ... } }` etc.

Rename to a generic `draft_controller.js`; delete `post_draft_controller.js`
(brave-forward: convert the Post composer to the generic controller, no shim).

### DraftRecoveryComponent reshape

Currently typed to `GamePresenter` + `ScenePresenter` + `PostPresenter`. It is
the "unsaved draft left behind" notice. For Page/SceneSummary the recovery
surface differs; reshape to take the draft presenter + a discard path rather
than scene-specific presenters, so all three adopters share it.

### The real work — read-path audit (draft must not leak to non-authors)

**SceneSummary — five places a draft can leak:**
1. `SceneSummary.public_for_game` (`app/models/scene_summary.rb`) — feeds HTML
   campaign log AND RSS. Add `.where(draft: false)` (i.e. `.published`).
2. `RssController#...` (`app/controllers/rss_controller.rb:29`) — inherits the
   scope fix above; verify.
3. `SceneSummariesController#index` (`:14`) — inherits scope fix; verify.
4. `SceneShowBuilder#summary_presenter` (`app/services/scene_show_builder.rb:71`)
   — `@scene.scene_summary` is a `has_one`, no scope applies. GM sees their own
   draft; a player must not. Branch on author/GM vs published.
5. `ScenePageAction` — `scene.scene_summary.blank?` decides whether "Write
   summary" appears. A draft makes it non-blank and hides the action. Not a
   leak, a behaviour change — gate on *published* presence, not bare presence.

**Page** — same treatment on its member-facing list (Page has no listing scope
today; add `published` scope and apply it to the members-facing index).

### Controllers/services for Page & SceneSummary drafting

- Add draft save endpoints mirroring `Posts::DraftsController` for the two new
  adopters (autosave JSON PATCH, discard). Follow the existing authz pattern
  (`verify_authorized`, capability predicate — never a role predicate).
- SceneSummary already builds via `scene.build_scene_summary`; publish promotes
  the same row (`draft: false`), consistent with the boolean decision.

### Tests

- Model specs: scopes, presence-unless-draft, publish! for each adopter.
- Read-path specs: each of the five SceneSummary leak points — a drafted
  summary is invisible to a non-author in log, RSS, index, scene show, and the
  footer action; visible to its GM author.
- Request specs for the new draft controllers.
- System spec (both viewports) for Page and SceneSummary draft → publish.
- Add new modules/components/presenters to `.mutant.yml`.

---

## Card #101 — Versionable: name the change-history concern

Generalizes from **Character only** (the sole existing implementation) — weaker
position for telling essential from incidental, so extract conservatively.

### Storage decision (owner input needed at build time — see Open Questions)

Two shapes:
- **Per-model versions tables** (as Character has now) — keeps column typing,
  costs a table + model per adopter.
- **One polymorphic `versions` table** with serialized payload — one migration,
  loses typing, awkward to query a version's content.

**Recommendation: per-model tables**, matching Character. Page would snapshot
`title` + `body`; SceneSummary would snapshot `body`. Preserves the existing
`character_versions` shape and the typed `*_versions/show` views. Confirm which
models actually want history before extracting (Page is the classic wiki case;
SceneSummary already keeps attribution but throws away prior text).

### Module shape (preserve the callback decision)

- **`Versionable::Model`** — overrides `save`/`save!` wrapped in a transaction,
  snapshotting via a pure `version_attributes` the adopter declares (which
  fields constitute a version). `Current.user || owner_id` attribution
  fallback generalizes. **No `after_save` callback** — `bin/check-callbacks`.
- Adopter declares its version association + which attributes to snapshot.

### Extract Character onto it, then adopt Page (and SceneSummary if confirmed)

- Character: move `save`/`save!` + `snapshot_version` into `Versionable::Model`;
  Character declares `content` as its versioned field. Keep behaviour identical
  (transaction rollback on failed snapshot, touch/update_column bypass).
- Page: `page_versions` table (`title`, `body`, `edited_by_id`, `created_at`),
  version-history component parameterized from
  `CharacterVersionHistoryComponent`.

### Tests

- Version snapshot on save/save! (not on touch/update_column), rollback on
  failed snapshot, attribution fallback — for Character (unchanged) and each new
  adopter.
- Regenerate RBIs (`bundle exec tapioca`) for new version models.
- `.mutant.yml` for new modules/components/presenters.

---

## Card #94 — Templates

Markdown templates, one per content type per game: page / note / character. A
`template` boolean on the content-type record; when a template exists for a
type, new records of that type start pre-filled with the template body.

### Shape (orthogonal to draft/version)

- `template` boolean on each content-type row (Page, NotebookEntry, Character —
  "page note character" per the card). One template per game per type to start.
- New-record forms for each type: if a template row exists for this
  (game, type), seed the body from it.
- Template is NOT a draft and NOT a version — a distinct boolean answering "is
  this the seed for new records of this type."

### Tests

- One-template-per-(game, type) enforced.
- New-record form pre-fills from the template when present, blank when absent.
- System spec (both viewports) for setting a template and creating a
  pre-filled record.

---

## Sequencing

1. **#100 Draftable first** — it gathers Post's existing machinery and is the
   most defined. Establishes the module/`abstract!` pattern the others follow.
2. **#101 Versionable second** — independent of drafting; confirm storage shape,
   extract Character, adopt Page.
3. **#94 Templates last** — orthogonal boolean; slots onto the same forms once
   Page's draft/version surfaces exist, avoiding rework.

## Open questions to resolve at build time

- **#101 storage**: confirm per-model tables (recommended) vs polymorphic, and
  confirm SceneSummary wants full version history (it keeps attribution today).
- **#94**: confirm the three content types (page/note/character) and that
  NotebookEntry ("note") is in scope for templates despite being out of scope
  for drafting.

## Gates

- `bundle exec rspec` green before any mutation read.
- `bin/pre-push` (fast tier) on push; `bin/full-check` for the heavy tier.
- `bundle exec srb tc` zero type errors.
- `bin/check-concerns`, `bin/check-callbacks`, `bin/check-view-layering`,
  `bin/check-design-tokens` all clean.
- Every new component/presenter in `.mutant.yml`.
