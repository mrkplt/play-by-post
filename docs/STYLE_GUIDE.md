# Play-by-Post UI Style Guide

The UI is **component-driven and mobile-first**. Colours, spacing, and radii come
from a single token layer; screens are assembled by composing ViewComponents;
and a set of automated gates enforce the pattern so it doesn't drift.

**See it live:** run the app in development and open **`/lookbook`** — the
browsable gallery of every `Ui::*` and `Shared::*` component (previews live in
`spec/components/previews/`).

---

## 1. Design tokens — the single source of truth

All colours and radii are defined once in the `@theme` block of
`app/assets/tailwind/application.css` and consumed as Tailwind utilities
(`bg-accent`, `text-tint-blue-strong`, `rounded-card`). **Never hard-code a hex
value in a class** (`bg-[#c8a96e]` is a gate failure — use `bg-accent`).

### Colour tokens

| Token | Utility example | Use |
|---|---|---|
| `--color-ink` | `text-ink` | primary dark text |
| `--color-canvas` | `bg-canvas` | light page background |
| `--color-sidebar-bg` | `bg-sidebar-bg` | dark header bars |
| `--color-drawer-bg` | `bg-drawer-bg` | nav drawer (darkest surface) |
| `--color-sidebar-text` | `text-sidebar-text` | text on dark surfaces |
| `--color-sidebar-border` | `border-sidebar-border` | dividers on dark surfaces |
| `--color-pill-idle` | `bg-pill-idle` | inactive pill tab |
| `--color-accent` / `--color-accent-ink` | `bg-accent text-accent-ink` | gold actions, active tab, crown; ink for text on gold |
| `--color-card` / `--color-card-border` / `--color-card-divider` | `bg-card border-card-border` | white cards + borders/dividers |
| `--color-input-border` | `border-input-border` | text input / textarea borders |
| `--color-muted` / `--color-muted-2` | `text-muted` | labels / tertiary meta |
| `--color-body-ink` / `--color-row-ink` | `text-body-ink` | post body / row secondary text |
| `--color-tint-blue-*` (`bg`, `border`, `strong`, `soft`) | `bg-tint-blue-bg` | the dormant/OOC/banned/removed tint family |
| `--color-danger` / `--color-danger-soft` | `text-danger` | ban / cancel / unban actions |

### Radii

`rounded-control` (8px, buttons/inputs) · `rounded-card` (10px) ·
`rounded-post` (12px) · `rounded-pill` (20px, pills/badges).

**Adding a colour:** add a token to `@theme` first, then use its utility. The
only sanctioned place for a raw palette hex is a component Ruby class's tone
table (e.g. `Ui::BadgeComponent::VARIANTS`, `Ui::AvatarComponent::TONES`) — the
token gate scans ERB, not Ruby, so those small, contained palettes are allowed.

---

## 2. Component library

Two namespaces, enforced by convention:

- **`Ui::*` — primitives.** Reusable, domain-agnostic. May compute additive CSS
  strings (BASE + variant) but must **not** inspect model state or branch on
  domain data. `Avatar`, `Badge`, `Breadcrumb`, `Button`, `Flash`, `Glow`,
  `IconButton`, `PillTabs`, `SectionLabel`, `SettingsRow`, `ToggleSwitch`.
- **`Shared::*` — domain components.** Compose `Ui::*` primitives and know about
  the domain. `GameHeader`, `NavDrawer`, `GameCard`, `SceneCard`, `RosterRow`,
  `PostItem`, `PostComposer`, `PageHeader`, `MobileFrame`, `Gallery`, …

### Site-wide scaffolds

Screens do not repeat chrome. They compose:

- **`app/views/layouts/application.html.erb`** — the one page shell (head, nav
  drawer, flash, `yield`).
- **`Shared::MobileFrameComponent`** — the per-screen scaffold: `header` slot
  (dark), body (default content), optional pinned `footer` slot.
- **`Shared::PageHeaderComponent`** (non-game screens) and
  **`Shared::GameHeaderComponent`** (game area, with the Scenes/Roster/Files pill
  tabs) — the shared headers.
- **`Shared::NavDrawerComponent`** — the global hamburger nav.

A new screen = compose a `MobileFrame` + a header + existing components. If you
find yourself writing bespoke markup, that markup probably wants to be a
component.

---

## 3. Template rules (enforced)

- **Tailwind only** for new work. Do not add to
  `app/assets/stylesheets/application.css` (legacy).
- **No logic in ERB output.** No ternaries (`<%= a ? b : c %>`), no `||`
  fallbacks (`<%= a || b %>`), no local assignments (`<% x = … %>`). Extract to a
  presenter or component method that returns the final string/value.
- **No raw hex in classes.** Use a token (see §1).
- **Presenters** hold presentation logic (formatted strings, CSS-class selection
  from model state, derived boolean flags). **ViewComponents** hold visual
  structure. Every method a component template calls on a presenter needs an
  explicit Sorbet `sig` (SimpleDelegator passthrough is invisible to Sorbet).

---

## 4. How adherence is enforced

Enforcement runs on every PR and push (and in the local `bin/pre-push` hook).
Each check is its **own CI job**, so a failure is identifiable directly from the
status list — the failing job is named for the thing that failed:

| Check (CI job) | Rule |
|---|---|
| **`design_tokens`** (`bin/check-design-tokens`) | no raw hex in ERB class utilities (`bg-[#…]`); use a `@theme` token. Fails itself on any violation. |
| **`mutant_registration`** (`bin/check-mutant-coverage`) | every concrete `app/` class (components, presenters, models, …) is in `.mutant.yml`. Fails itself if any is missing. |
| **`lint` / `typecheck`** | RuboCop / Sorbet |
| **`quality_gate`** (`bin/quality-metrics --check`) | evaluates *produced* outcomes vs baseline: coverage (≥80% line / ≥70% branch on changed files, mutation floor), view-CSS-must-not-increase, ERB-logic-must-not-increase, presenter-method ceiling, Sorbet sigils |

The two static checks are **standalone executables** that own their pass/fail
(`exit 1` on violation) — they don't route through `quality_gate`, which is
reserved for evaluating expensive-to-produce numbers (coverage, mutation). Run
them locally any time: `bin/check-design-tokens`, `bin/check-mutant-coverage`.

**When you add a component:** create it under `Ui::*`/`Shared::*`, add a spec, a
Lookbook preview in `spec/components/previews/`, and register its constant in
`.mutant.yml` (the `mutant_registration` job fails the build otherwise).
