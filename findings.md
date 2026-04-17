# Views Architecture Review — Refactoring Candidates

A review of `app/views/` for ERB templates that violate the project's
presenter + ViewComponent architecture (as documented in `.claude/CLAUDE.md`).

## Tier 1 — Dead partials (violates CLAUDE.md, delete immediately)

CLAUDE.md is explicit: _"Delete old partials once fully replaced."_ These were
replaced by ViewComponents but the old partials were never deleted. They are
not referenced anywhere in the application.

- `app/views/game_files/_gallery.html.erb` (60 lines) — no references;
  superseded by `Shared::GalleryComponent`.
- `app/views/scenes/_scene_card.html.erb` (42 lines) — no references;
  superseded by `Shared::SceneCardComponent`.
- `app/views/scenes/_tree_node.html.erb` (28 lines) — only self-references;
  superseded by `Shared::TreeNodeComponent`.

## Tier 2 — Logic that should move into the presenter/component class

### `Shared::GalleryComponent` template

`app/components/shared/gallery_component.html.erb` still builds four
computed values inside an ERB code block:

- `thumb_html`
- `download_url`
- `delete_url`
- `lightbox_html` — a multi-branch `tag.div` / `tag.img` construction

These are pure computation with no loop-dependent state that couldn't be
expressed as methods. They should be `sig`-typed methods on
`GameFilePresenter` (or a new `GalleryCardPresenter`) plus a small amount of
URL logic on the component class itself. The template should only iterate
and render.

### Other similar cases

- `app/views/scenes/show.html.erb:90` hand-builds the participant list string
  with `@scene.scene_participants.includes(:character, :user).map(&:display_name).join(", ")`.
  `ScenePresenter#participant_names` already exists but the view doesn't use
  `@scene_presenter` here.
- `app/views/scenes/show.html.erb:122-130` constructs
  `PostPresenter.new(post, scene_participants: participants)` inside the
  loop — the controller should supply pre-decorated presenters.
- `app/views/scenes/new.html.erb:45` builds `parent_options` inline —
  belongs on a presenter.
- `user.display_name || user.email` appears ~8 times across views
  (`games/show`, `player_management`, `characters/show`, `profiles/show`,
  `character_versions/show`). `UserPresenter#display_name_or_email` exists
  but is unused.

## Tier 3 — New components to extract

### `scenes/show.html.erb` (160 lines)

Three distinct components are tangled together in this template:

1. Scene header + action menu dropdown (lines 11-114) —
   `Shared::SceneHeaderComponent`.
2. Resolve form (lines 99-114) — its own component.
3. Draft recovery notice (lines 144-153) —
   `Shared::DraftRecoveryComponent`.
4. Child scene list (lines 76-87) — duplicates Active/Resolved badge logic
   that lives in `scene_card_component` and `tree_node_component`.

### Other extraction candidates

- `app/views/games/show.html.erb:34-41` — character roster card →
  `Shared::CharacterCardComponent`.
- `app/views/games/index.html.erb:16-32` — dashboard game item →
  `Shared::DashboardGameItemComponent`.
- `app/views/player_management/show.html.erb` (101 lines) — members table and
  pending invitations table → two components. The status/role pill classes
  are recomputed inline (e.g. `member.game_master? ? 'bg-blue-100 text-blue-700' : 'bg-green-100 text-green-800'`).
- `app/views/scenes/new.html.erb` and
  `app/views/scene_participants/edit.html.erb` both render the same "players
  with characters" checkbox list → `Shared::ParticipantCheckboxListComponent`.

## Tier 4 — Cross-cutting: `Ui::ButtonComponent` is unused

`Ui::ButtonComponent` (`app/components/ui/button_component.rb`) exists with
variants and sizes, but **zero views call it**. Consumers are only the
component spec, the Lookbook preview, and `.mutant.yml`.

The class soup
`"px-5 py-2 bg-slate-500 text-white rounded text-base cursor-pointer hover:bg-slate-600 inline-block no-underline"`
is duplicated ~30+ times across views (and its danger/secondary siblings
another ~10).

The component's current palette (`bg-blue-600`) also doesn't match what the
views actually use (`bg-slate-500`), which is likely why it was never
adopted — the component needs its palette aligned to actual usage, then a
sweep across views to adopt it.

## Suggested sequencing

1. **Tier 1** — pure deletion, zero risk, closes the partial/component
   duplication immediately.
2. **Tier 2 — `GalleryComponent` cleanup** — scoped and small; demonstrates
   the presenter pattern clearly.
3. **Tier 3** — one component per PR to keep blast radius small; start with
   the duplicated participant checkbox list since it removes duplication in
   two views at once.
4. **Tier 4** — highest leverage but widest blast radius; align
   `Ui::ButtonComponent`'s variants with actual palette first, then sweep
   views in a dedicated PR.
