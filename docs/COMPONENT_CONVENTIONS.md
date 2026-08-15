# Component & View Conventions

**Read when:** writing or changing any ViewComponent, presenter, form, or view.
Visual design (tokens, palette, spacing) is `docs/STYLE_GUIDE.md`; this file is code structure.

---

## Presenters & ViewComponents

**Role split — enforce strictly:**
- **Presenters hold data transformation:** mutating model data into presentation-ready shape — formatted timestamps, display-ready strings, derived boolean flags, computed display values. Presenters do NOT handle CSS class selection or visual concerns.
- **ViewComponents hold visual presentation:** HTML structure, CSS class selection based on model state, which sub-components to render, slot content. A component's Ruby class may compute CSS class strings that are purely additive (e.g. combining a BASE constant with a variant).

**When implementing or updating a ViewComponent:**
- Always introduce new ViewComponents instead of raw HTML — never hand-write bespoke screen markup
- Survey the codebase for similar implementations in HTML and refactor them into the component
- Variations on a theme should be parameterized (size variants, accent options, etc.) rather than creating separate components
- **Gold standard patterns:** `Ui::IconComponent` (domain-specific mapping with size/accent parameters) and `Ui::MarkdownRenderComponent` (configurable rendering)
- New components must be registered in `.mutant.yml` and have full test coverage

**Component structure:**
- Ruby class + ERB template pair in `app/components/{namespace}/{name}_component.rb` and `.html.erb`
- Namespace by purpose: `Ui::*` for primitives (reusable across apps), `Shared::*` for domain-specific (project-specific)
- Type annotations: `# typed: strict` on all component Ruby files

**Variants & parameters:**
- Parameterize variations rather than creating separate components (e.g., `Ui::IconComponent` handles size/accent)
- Use constants for fixed options (like `SIZES`, `ICON_MAP` in the Icon component)
- Provide sensible defaults so callers only specify what differs

**Composition patterns:**
- Use `renders_one` / `renders_many` for complex component composition (slots)
- Use `content` for simple HTML wrapping
- Extract reusable pieces as separate components rather than duplicating

**Testing components:**
- Component specs in `spec/components/{namespace}/`
- Test all variants — iterate over constants like `SIZES.each_key` to ensure all combinations render
- Use `render_inline` for assertions (not `render_component`)
- Mock external dependencies — use `instance_double` for services/models

**CSS handling:**
- Tailwind only — no inline styles, no separate CSS files for new components
- Compose classes from constants and parameters (like `BASE + variant`)
- No raw hex — use design tokens from `@theme`

**Migration patterns:**
- Extract from views when HTML patterns repeat — replace partials, delete old partials once fully replaced
- Refactor incrementally — don't rewrite entire views at once; extract one component at a time

**ERB template rules — no logic in templates:**
- No ternaries in output tags: `<%= a ? b : c %>` → extract a method
- No Boolean-OR fallbacks in output tags: `<%= a || b %>` → extract a method
- No inline conditionals on HTML attributes: `<div <% if x %> data-foo="bar"<% end %>>` → extract a method that returns the attribute hash

**Sorbet:**
- `BasePresenter < SimpleDelegator` silently exposes all model methods, but **Sorbet cannot see them**. Every method a ViewComponent template calls on a presenter must be explicitly declared on the presenter with a Sorbet `sig`. Do not rely on `SimpleDelegator` passthrough.

**Other rules:**
- Happy path and error path in the same controller action must render the same component. Never mix a ViewComponent in one branch and a partial in the other. Delete old partials once fully replaced.
- Component namespaces: `Ui::*` for primitives, `Shared::*` for domain components.

**Components own their content — they are not thin HTML wrappers.** A "status badge row" or a "labeled control row" component holds its labels/controls/conditions and *is* the pattern; wrapping an already-shared primitive (e.g. nesting two `Ui::BadgeComponent` renders inside conditionals) only to add a container is not extraction. But a component takes **derived, presentation-ready data, never a raw model**: `Shared::StatusBadgeRowComponent` takes a pre-computed `[{label:, variant:}]` array (a presenter picks the symbolic `variant:` from `Ui::BadgeComponent`'s palette) — it does not receive a `Scene`/`Character` and compute `.private?`/`.resolved?` itself. That would violate the presenter/component split and force a `T.any(...)` sig across model shapes.

That array's shape is declared as `Badge = T.type_alias { { label: String, variant: Symbol } }` — **a named interface for data, not a class**. Note the two things both called "badge" and keep them straight: `Ui::BadgeComponent` is the *component* that renders one badge; `Badge` is the *shape* of the data describing one before it becomes a component. The presenter says "Private, yellow" (display logic); the row component decides that means a `Ui::BadgeComponent` (markup). Keeping construction in the component is why a change to how badges render is one edit rather than one per presenter.

**`bin/check-view-layering` is the enforced statement of these rules** — it fails on a model reaching a view ivar, a presenter or component, and its output explains the whole layering contract. Read the gate rather than restating its rules here; the two drift otherwise. Two things it encodes that are easy to get wrong from memory: classification is by **inheritance, not name** (a `FooPresenter` that does not inherit `BasePresenter` is not a presenter), and a **hash is opaque** — the gate permits hashes without inspecting them, because the hash is where irregular front-end reality is allowed to live. Arrays, tuples and type aliases *are* resolved through to their contents, which is why `Badge` (a hash) passes and a tuple holding `T::Array[Character]` does not.


## Navigation architecture (target shell)

The app has **two-tier navigation**, and the fix for "varying presentation" is that *one* header renders on every screen (varying markup per screen is the bug, not the goal):
- **Tier 1 (site-wide):** the hamburger opens the global nav drawer (`Shared::NavDrawerComponent`, always in the DOM via `application.html.erb`). The drawer only *opens* if a hamburger button (`data-action="click->sidebar#open"`) is on the page — so every header must render one. A back-arrow-only header is a nav dead-end.
- **Tier 2 (in-game):** the pill tabs (`Ui::PillTabsComponent`, `:switch` = client-side panels on `games/show`, `:link` = cross-page).

**The universal-header pattern:** one `Header` component on every screen, exposing a **generic `secondary_nav:` slot** (plus nilable `gear:`/`breadcrumbs:`). A screen passes the section's menu into the slot — `GameNav` for game sections, nothing for a plain page, another section's menu later — with no change to `Header`. "Which menu" is a passed-in component, never a hand-rolled per-screen layout. This is the standardization mechanism; reuse the `renders_one` slot idiom already in `Shared::MobileFrameComponent` (header/footer slots — the footer is where a page's action buttons belong, not mid-body).

Responsive is **CSS `@media` at 1024px**, not template variants (evaluated and rejected: UA gives device-class not viewport-width, and Turbo restoration visits serve a cached variant with no re-negotiation). The live conditional-nav CSS is only ~3 rules; don't mistake it for complexity worth a variant split.

## Forms & text fields

- **Every user-editable multi-line text field is a markdown field.** If a person can type multi-line prose into it, it must render markdown on display **and** carry the standard editing affordances: the `Shared::MarkdownToolbarComponent` toolbar directly above the textarea, plus a live `markdown-base` preview below it (wire the form with `data: { controller: "markdown-preview markdown-toolbar" }` and the textarea with the `markdown-preview`/`markdown-toolbar` targets + `input->markdown-preview#update`). Render the stored value through `MarkdownRenderer` wherever it is shown. There is no "plain textarea for prose" — do not add one. Copy the wiring from `Shared::PageFormComponent` / `Shared::GameFormComponent`.
- **Single-line identifier inputs are the only exception** (e.g. game name, scene title): short labels, not prose — no toolbar, no markdown.
- **Campaign Notebook entries are the one deliberate no-preview field.** They keep the toolbar and render markdown once promoted, but the edit screen is a large writing surface with no live preview: entries are GM scratchpad, not published content, so presentation waits until the entry becomes a Page. Do not "fix" this back.
- Every prose field is migrated: post composer/edit, character sheets, scene summaries, game description, scene resolution/outcome, and the feedback modal body. There is no remaining plain-textarea prose field — keep it that way.

**The markdown editor is composed of regions, not toggled by flags.** `Ui::MarkdownEditorComponent::Config` carries a `regions:` collection (`ToolbarRegion`, `PreviewRegion`); each region reports where it sits and which component fills it, and the editor enumerates rather than branching. Turning a region off means omitting it — there is no `toolbar:`/`preview:` boolean. `Config.with_preview(preview_class:)` builds the usual toolbar-plus-preview surface most callers want. Heights are steps on `Config::HEIGHTS` (`sm` 20vh / `md` 30vh / `lg` 40vh / `xl` 60vh), never raw px; `HEIGHTS.fetch` raises on anything off-scale. `rows:` is an editor parameter, not layout config.

## CSS
- New work: Tailwind only. Do not add to `app/assets/stylesheets/application.css` (legacy, migration in progress).
- Never edit `app/assets/builds/` (generated).


## Policies & authorization

**Every policy question is one of three distinct things, and they must not collapse into each other:**
- **System function** — Pundit/ActiveRecord vocabulary (`update?`, `destroy?`, `show?`) meaning "this row may be modified/deleted/viewed." Exists because `authorize`/`policy_scope` infer the method name from `action_name`.
- **Role** — a domain fact about a person (`gm?`, `owner?`, `write_member?`): who they are, not what they're allowed to do.
- **Game function (capability)** — what is actually being decided: "may this user manage this game's pages," "may this user resolve this scene." This is the stable concept; who satisfies it is not.

**Domain understanding this encodes:** a GM is currently the same person as the game owner, but that will not always be true — a game owner may not be a GM, a game may have many GMs or none, and GM-only functions may later granularize to permission levels or specific players. Writing the capability *as* the role (`policy(@game).update?` meaning "is this user the GM") bakes `owner == GM == can-do-everything` into every call site, so the rule can never change in one place.

**The rule:**
- **Capability predicates are the public surface.** Controllers, views, components, and presenters ask only capability questions, named for the game function (`manage?`, `resolve?`, `manage_participants?`, `participate?`, `assign_owner?`) — never a role question and never a bare CRUD predicate borrowed for a different purpose.
- **Role predicates stay `private`** inside the policy. They are the *implementation* of a capability — the one line that changes when a rule granularizes.
- **`update?`/`destroy?`/`show?` remain**, because Pundit infers them from `action_name`, but their bodies must delegate to a capability predicate, not duplicate the role check.
- **`policy(x).update?` (or `.show?`) must never be used as a stand-in for "is GM" (or "can view").** If a call site is asking a capability question, it calls a capability predicate — `GamePolicy#manage?` / `#view?`, not `#update?` / `#show?` reused out of convenience.
- **Do not add a public role-named method anywhere** (e.g. a public `GamePolicy#game_master?`) — that's the same mistake one level down: a role back on the public surface.

This extends to the view layer: a component parameter or presenter method is a public API too, so it is named for the capability (`can_manage:`, `GamePresenter#can_manage?`), never the role. A predicate answering an authorization question must ask the policy — `Shared::SidebarComponent` once read `member_for(user).game_master?` directly, which looks converted once its call site is renamed but silently diverges from every other check the day the rule granularizes.

**The completion test: `gm?` must have exactly one caller — the capability.** If it appears in three CRUD bodies, granularizing means editing three lines, which is the thing this convention exists to prevent. Every policy satisfies this except `CharacterPolicy`, where `assign_owner?` and `manage_roster?` are deliberately distinct game functions that happen to share a rule today.

**Copy `GamePolicy#manage?`/`#view?` or `NotebookEntryPolicy#manage?`** — both implement the rule end to end: CRUD predicates delegate, role predicates are private.

**When converting a call site, convert the controller and its views together.** A view gated on `can_manage?` whose controller still loads the data under `update?` is identical today and raises `NoMethodError` on nil the day they diverge — a split-brain that is harder to spot than the original conflation.
