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

---

## Implementation Plan — Tier 1 & Tier 2

### Step ordering

Tier 1 first (pure deletion, no risk). Within Tier 2: **2c before 2b** (controller must
supply `@post_presenters` before the view consumes it); 2d independently; 2e last
(touches the most files).

---

### Tier 1 — Delete dead partials

**1.1** Delete `app/views/game_files/_gallery.html.erb` — zero call sites confirmed.

**1.2** Delete `app/views/scenes/_scene_card.html.erb` — zero call sites confirmed.

**1.3** Delete `app/views/scenes/_tree_node.html.erb` — only reference is the
self-recursive call inside the file itself.

No new tests needed for any of the three deletions. Run the existing component
specs to confirm nothing regresses.

---

### Tier 2a — `Shared::GalleryComponent` template cleanup

**2a.1** Add `display_image` proxy to `app/presenters/game_file_presenter.rb`:

```ruby
sig { returns(T.nilable(ActiveStorage::VariantWithRecord)) }
def display_image
  @model.display_image
end
```

Required so Sorbet can see the method — SimpleDelegator passthrough is invisible.

**2a.2** Add four private helper methods to `app/components/shared/gallery_component.rb`
(each with an explicit `sig`):

- `download_url_for(gf) → String`
- `delete_url_for(gf) → T.nilable(String)` — nil when current user is not GM
- `thumb_html_for(gf) → T.nilable(String)`
- `lightbox_html_for(gf) → String` — three branches: image with display_image,
  thumbnail fallback, text placeholder

Use `helpers.url_for(...)` and `helpers.image_tag(...)` — ViewComponent's `helpers`
proxy is already used elsewhere in the codebase.

**2a.3** Simplify `app/components/shared/gallery_component.html.erb`: replace the
four inline `<% ... %>` computation blocks with calls to the new component methods.

**Tests:** New specs in `spec/components/shared/gallery_component_spec.rb` for each
branch of each helper method. New specs in `spec/presenters/game_file_presenter_spec.rb`
for `#display_image`.

---

### Tier 2b — `scenes/show.html.erb` participant list

**2b.1** Replace `app/views/scenes/show.html.erb` line 90:

```erb
<%# Before %>
Participants: <%= @scene.scene_participants.includes(:character, :user).map(&:display_name).join(", ") %>
<%# After %>
Participants: <%= @scene_presenter.participant_names %>
```

`@scene_presenter` is already assigned in the controller. `ScenePresenter#participant_names`
already exists with a `sig`. No Ruby changes needed.

**Tests:** Add an assertion to the `show` context in `spec/requests/scenes_spec.rb`
that a participant's display name appears in the response body.

---

### Tier 2c — Pre-decorated `PostPresenter` objects from the controller

**2c.1** In `ScenesController#show` (`app/controllers/scenes_controller.rb`), after
`@posts` is assigned:

```ruby
participants = @scene.scene_participants.includes(:character, :user).to_a
@post_presenters = T.let(
  @posts.map { |post| PostPresenter.new(post, scene_participants: participants) },
  T::Array[PostPresenter]
)
```

This also fixes a latent N+1 — the view's current `to_a` lacked `includes`.

**2c.2** Update `app/views/scenes/show.html.erb` lines 121-130 to iterate
`@post_presenters` instead of constructing `PostPresenter.new(...)` inline. Delete
the `<% participants = ... %>` local assignment line.

**Tests:** Extend the `show` spec to assert a post author's display name appears in
the response body (exercises the `scene_participants` path through the presenter).

---

### Tier 2d — `parent_options` in `scenes/new.html.erb`

**2d.1** Add to `app/presenters/scene_presenter.rb`:

```ruby
sig { returns(String) }
def parent_option_label
  @model.resolved? ? "#{@model.title} (Resolved)" : @model.title
end
```

**2d.2** In `ScenesController#new` and `#create`, wrap `@parent_scene_options`
elements in `ScenePresenter` with a `T.let` annotation.

**2d.3** Simplify `app/views/scenes/new.html.erb` line 45: replace the inline
ternary with `@parent_scene_options.map { |s| [s.parent_option_label, s.id] }`.

**Tests:** Specs for `#parent_option_label` in `spec/presenters/scene_presenter_spec.rb`
(active → plain title; resolved → title + " (Resolved)"). Extend the `new` context in
`spec/requests/scenes_spec.rb` to assert "(Resolved)" appears in the select options
for a resolved scene.

---

### Tier 2e — `user.display_name || user.email` → `UserPresenter#display_name_or_email`

Eight occurrences across six views. All replaced with inline
`UserPresenter.new(user).display_name_or_email` calls:

| File | Current expression |
|------|--------------------|
| `app/views/games/show.html.erb:39` | `character.user.display_name \|\| character.user.email` |
| `app/views/characters/show.html.erb:15` | `@character.user.display_name \|\| @character.user.email` |
| `app/views/characters/show.html.erb:47` | `version.edited_by.display_name \|\| version.edited_by.email` |
| `app/views/character_versions/show.html.erb:14` | `@version.edited_by.display_name \|\| @version.edited_by.email` |
| `app/views/scenes/new.html.erb:26` | `user.display_name \|\| user.email` |
| `app/views/scene_participants/edit.html.erb:9` | `user.display_name \|\| user.email` |
| `app/views/player_management/show.html.erb:40` | `member.user.display_name \|\| "—"` — note: currently uses em-dash fallback, not email; change to `display_name_or_email` for consistency and update `context/REQUIREMENTS.md` |

**Tests:** For each affected view, add/extend its request spec to assert that a user
with no display name shows their email prefix (not empty, not `"—"`, not raw email).

---

### After all steps

1. Update `context/REQUIREMENTS.md`:
   - Gallery component: URL/HTML construction moved to typed component methods
   - Player management display name column falls back to email prefix (not em-dash)
   - Post presenters are constructed in the controller, not the view
2. Run `bin/pre-push` (rubocop → brakeman → `srb tc` → rspec → mutant →
   quality-metrics gate)
3. Commit and push to `claude/plan-tier-fixes-and0H`
