# Tailwind CSS Migration Plan — Big-Bang Refactor

## Context

Migrate from hand-written vanilla CSS (`app/assets/stylesheets/app.css`, 537 lines) to Tailwind CSS in a single refactor. Replace all custom CSS classes and inline `style=""` attributes with Tailwind utility classes. Fix tests as needed. No incremental migration — full replacement in one pass.

**Stack:** Rails 8.1.3, Ruby 4.0.2, Propshaft (asset pipeline), importmap-rails (ESM JS, no bundler), Hotwire/Turbo/Stimulus.

---

## Phase 0: Infrastructure Setup

- [ ] Add `gem "tailwindcss-rails"` to `Gemfile`
- [ ] `bundle install`
- [ ] `bin/rails tailwindcss:install`
  - Creates `app/assets/tailwind/application.css` (Tailwind input)
  - Creates `app/assets/builds/tailwind.css` (generated output)
  - Updates layout to reference `tailwind` stylesheet
- [ ] Update `Procfile.dev` — ensure it has:
  ```
  web: bin/rails server -p 3000
  css: bin/rails tailwindcss:watch
  ```
- [ ] Update `bin/dev` to run both processes via foreman/overmind
- [ ] Add to `.gitignore`:
  ```
  /app/assets/builds/*
  !/app/assets/builds/.keep
  ```

---

## Phase 1: Tailwind Configuration

File: `app/assets/tailwind/application.css`

```css
@import "tailwindcss";

@theme {
  --color-ink: #1a1a1a;
  --color-canvas: #fafafa;
}

@layer base {
  body { @apply font-sans text-base leading-relaxed text-ink bg-canvas; }
  a { @apply text-blue-600; }
  a:hover { @apply no-underline; }
  table { @apply w-full border-collapse; }
  th, td { @apply text-left px-3 py-2 border-b border-slate-200; }
  th { @apply font-semibold text-sm text-slate-500; }
}

@layer components {
  /* Markdown-rendered content — can't inject Tailwind classes into server-rendered HTML */
  .character-sheet { @apply leading-relaxed; }
  .character-sheet p { @apply m-0 mb-2; }
  .character-sheet h1,
  .character-sheet h2,
  .character-sheet h3 { @apply mt-4 mb-2; }
  .character-sheet ul,
  .character-sheet ol { @apply my-1 mb-2 pl-6; }
  .character-sheet table { @apply my-2; }
  textarea.character-sheet { @apply font-mono whitespace-pre-wrap; }

  /* Post content image safety */
  .post-content img { @apply max-w-full h-auto block; }
}
```

### Color Mapping (current hex → Tailwind)

| Hex | Tailwind |
|---|---|
| `#1e293b` | `slate-800` |
| `#2563eb` | `blue-600` |
| `#1d4ed8` | `blue-700` |
| `#f8fafc` | `slate-50` |
| `#94a3b8` | `slate-400` |
| `#64748b` | `slate-500` |
| `#475569` | `slate-600` |
| `#334155` | `slate-700` |
| `#e2e8f0` | `slate-200` |
| `#cbd5e1` | `slate-300` |
| `#f1f5f9` | `slate-100` |
| `#1a1a1a` | `text-ink` (custom) |
| `#fafafa` | `bg-canvas` (custom) |
| `#dc2626` | `red-600` |
| `#b91c1c` | `red-700` |
| `#991b1b` | `red-800` |
| `#166534` | `green-800` |
| `#854d0e` | `yellow-800` |
| `#dcfce7` | `green-100` |
| `#fef2f2` | `red-50` |
| `#dbeafe` | `blue-100` |
| `#fef9c3` | `yellow-100` |
| `#fecaca` | `red-200` |

---

## Phase 2: Convert All Views

Replace every custom CSS class and inline `style=""` with Tailwind utilities across all 20 non-mailer views and 6 partials.

### CSS Class → Tailwind Reference

#### Layout & Structure
```
.navbar              → flex items-center justify-between px-6 py-3 bg-slate-800 text-slate-50 flex-wrap
.navbar__brand       → font-bold text-lg text-slate-50 no-underline
.navbar__actions     → flex items-center gap-4 text-sm
.navbar__user        → text-slate-400
.navbar__link        → text-slate-50 no-underline
.navbar__hamburger   → md:hidden flex flex-col justify-center items-center gap-[5px] w-11 h-11 bg-transparent border-none p-0 cursor-pointer text-slate-50
.navbar__hamburger-bar → block w-[22px] h-0.5 bg-current rounded-sm
.navbar__menu        → w-full flex-col bg-slate-800 md:flex md:flex-row md:w-auto
```

#### Flash Messages
```
.flash.flash--notice → px-4 py-3 rounded mb-4 text-sm bg-green-100 text-green-800
.flash.flash--alert  → px-4 py-3 rounded mb-4 text-sm bg-red-50 text-red-800
```

#### Auth & Forms
```
.auth-card           → max-w-sm mx-auto mt-16 p-8 bg-white border border-slate-200 rounded-lg
.field               → mb-4
.field label         → block font-medium mb-1 text-sm
.field input/textarea/select → w-full px-3 py-2 border border-slate-300 rounded text-base
.field-error         → text-red-600 text-sm
```

#### Buttons
```
.btn                 → px-5 py-2 bg-blue-600 text-white rounded text-base cursor-pointer hover:bg-blue-700 inline-block no-underline
.btn--secondary      → px-5 py-2 bg-slate-500 text-white rounded text-base cursor-pointer hover:bg-slate-600 inline-block no-underline
.btn--danger         → px-5 py-2 bg-white text-red-600 border border-red-200 rounded text-base cursor-pointer hover:bg-red-50 inline-block no-underline
.btn--small          → text-xs px-2 py-1
input[type=submit]   → use .btn classes directly
```

#### Cards & Sections
```
.card                → bg-white border border-slate-200 rounded-lg p-5 mb-4
.section             → mb-10
.section__header     → flex items-center justify-between mb-4
.section__header h2  → m-0 text-xl font-semibold
```

#### Badges
```
.badge               → inline-block px-2 py-0.5 rounded-full text-xs font-semibold
.badge--blue         → bg-blue-100 text-blue-700
.badge--green        → bg-green-100 text-green-800
.badge--yellow       → bg-yellow-100 text-yellow-800
.badge--red          → bg-red-50 text-red-800
.badge--gray         → bg-slate-100 text-slate-600
```

#### Posts
```
.post                → border-b border-slate-100 py-4 last:border-b-0
.post__meta          → text-xs text-slate-500 mb-1
.post__content       → whitespace-pre-wrap post-content   ← keep "post-content" for @layer img rule
.post--ooc           → bg-slate-50 border-l-[3px] border-slate-400 pl-3 opacity-60 hover:opacity-85 text-[0.9em]
.post-composer-actions → flex gap-2 flex-wrap
```

#### Scene Tree
```
.scene-tree          → text-sm
.tree-node           → mb-0.5
.tree-node__row      → flex items-center gap-2 px-2 py-1 rounded
  modifier --active  → add font-semibold
  modifier --resolved → add text-slate-500 [a elements also get text-slate-500]
.tree-node__connector → text-slate-400 font-mono shrink-0
.tree-node__title    → whitespace-nowrap
.tree-node__meta     → text-xs text-slate-400 ml-auto whitespace-nowrap
```
> **Note:** Dynamic `margin-left` (`style="margin-left:<%= depth * 1.5 %>rem"`) stays as inline style — computed at runtime, cannot use Tailwind.

#### Gallery
```
.gallery-grid        → grid grid-cols-[repeat(auto-fill,minmax(180px,1fr))] gap-4
.gallery-grid--compact → grid-cols-[repeat(auto-fill,minmax(100px,120px))] gap-2
.gallery-card        → bg-white border border-slate-200 rounded-lg overflow-hidden cursor-pointer relative hover:shadow-md transition-shadow
.gallery-card__thumb → w-full aspect-square flex items-center justify-center bg-slate-50 overflow-hidden
.gallery-card__thumb img → w-full h-full object-cover
.gallery-card__placeholder → text-2xl font-bold text-slate-500 uppercase tracking-wide bg-slate-100 w-full h-full flex items-center justify-center
.gallery-card__info  → p-2 flex items-center gap-1
.gallery-card__filename → flex-1 min-w-0 text-xs text-ink whitespace-nowrap overflow-hidden text-ellipsis
```

#### Lightbox Modal
```
.lightbox            → fixed inset-0 z-[1000] flex items-center justify-center p-4
.lightbox[hidden]    → hidden
.lightbox__backdrop  → absolute inset-0 bg-black/60
.lightbox__content   → relative bg-white rounded-lg max-w-[90vw] max-h-[90vh] flex flex-col overflow-hidden
.lightbox__header    → flex items-center justify-between px-4 py-3 border-b border-slate-200 gap-4
.lightbox__title     → font-semibold text-sm min-w-0 whitespace-nowrap overflow-hidden text-ellipsis
.lightbox__header-actions → flex items-center gap-2 shrink-0
.lightbox__close     → bg-transparent border-none text-xl cursor-pointer text-slate-500 p-1 leading-none hover:text-ink
.lightbox__body      → flex items-center justify-center p-4 overflow-auto flex-1
.lightbox__body img  → max-w-full max-h-[80vh] object-contain
.lightbox__placeholder → flex flex-col items-center justify-center gap-3 p-8 text-slate-500
.lightbox__placeholder-ext → text-5xl font-bold text-slate-400
.lightbox__placeholder-size → text-sm text-slate-400
```

#### Tables
```
.table-responsive    → overflow-x-auto
```
(Table/th/td base styles handled in @layer base)

### Files to Convert

**Layouts:**
- [ ] `app/views/layouts/application.html.erb` — swap stylesheet link to `tailwind`, convert body/main/flash
- [ ] `app/views/layouts/_navbar.html.erb`

**Auth/Profile:**
- [ ] `app/views/users/sessions/new.html.erb`
- [ ] `app/views/profiles/show.html.erb`
- [ ] `app/views/profiles/edit.html.erb`

**Games:**
- [ ] `app/views/games/index.html.erb`
- [ ] `app/views/games/show.html.erb`
- [ ] `app/views/games/new.html.erb`

**Characters:**
- [ ] `app/views/characters/show.html.erb`
- [ ] `app/views/characters/new.html.erb`
- [ ] `app/views/characters/edit.html.erb`
- [ ] `app/views/character_versions/show.html.erb`

**Scenes:**
- [ ] `app/views/scenes/index.html.erb`
- [ ] `app/views/scenes/show.html.erb` ← largest view (141 lines, 25+ inline styles)
- [ ] `app/views/scenes/new.html.erb`
- [ ] `app/views/scenes/_scene_card.html.erb`
- [ ] `app/views/scenes/_tree_node.html.erb`
- [ ] `app/views/scene_participants/edit.html.erb`

**Posts:**
- [ ] `app/views/posts/_post_item.html.erb`
- [ ] `app/views/posts/_composer.html.erb`
- [ ] `app/views/posts/edit.html.erb`
- (turbo stream templates render partials — no direct changes needed)

**Game Files:**
- [ ] `app/views/game_files/index.html.erb`
- [ ] `app/views/game_files/_gallery.html.erb` ← most complex partial (lightbox + gallery)

**Player Management:**
- [ ] `app/views/player_management/show.html.erb`

**NOT converted (mailers — email clients need inline styles):**
- `app/views/layouts/mailer.html.erb`
- `app/views/devise/mailer/magic_link.html.erb`
- `app/views/invitation_mailer/invite.html.erb`
- `app/views/notification_mailer/new_scene.html.erb`
- `app/views/notification_mailer/post_digest.html.erb`
- `app/views/notification_mailer/scene_resolved.html.erb`

---

## Phase 3: Update Stimulus Controllers

**`app/javascript/controllers/markdown_preview_controller.js`**
- Replace `style.display = "none"/"block"` with `hidden` attribute toggling
- Remove inline `style="display:none"` from preview targets in views, replace with `hidden` attribute

**`app/javascript/controllers/ooc_filter_controller.js`**
- Replace `el.style.display = "none"/""` with `el.hidden = true/false`

**No changes needed:**
- `nav_controller.js` — already uses `hidden` attribute
- `lightbox_controller.js` — already uses `hidden` attribute
- `menu_controller.js` — already uses `hidden` attribute

---

## Phase 4: Fix System Specs

Update CSS class selectors to use `data-testid` attributes instead. Add `data-testid` to the relevant elements in views, update specs.

**Specs to update:**
- [ ] `spec/system/mobile_nav_spec.rb` — `.navbar__hamburger`, `.navbar__menu`
- [ ] `spec/system/mobile_posts_spec.rb` — `.post__content`, `.post--ooc`, `.post--reply`
- [ ] `spec/system/mobile_composer_spec.rb` — `.post-composer-actions`
- [ ] `spec/system/tablet_gm_dashboard_spec.rb` — `.navbar__hamburger`, `.navbar__menu`, `.btn`
- [ ] `spec/system/posts_spec.rb` — `.post--ooc`

**Pattern:** Add `data-testid="hamburger"` to element in view, update spec to `find('[data-testid="hamburger"]')`.

---

## Phase 5: Cleanup

- [ ] Delete `app/assets/stylesheets/app.css`
- [ ] Remove `stylesheet_link_tag :app` from layout (should already be replaced in Phase 2)
- [ ] Run full test suite: `bundle exec rspec`
- [ ] Fix any remaining test failures

---

## Phase 6: Visual Verification

Use Chrome browser automation to verify at 375px (mobile) and 1024px+ (desktop):

- [ ] Sign-in page — auth card centered, form fields
- [ ] Games index — game cards, badges, section header
- [ ] Game show — characters grid, scenes, game files
- [ ] Scene show — scene card, dropdown menu, posts, OOC filtering, composer
- [ ] Scene index — tree view with correct indentation
- [ ] Character show — markdown rendering in character sheet, version table
- [ ] Character new/edit — form fields, markdown preview toggle
- [ ] Game files — gallery grid (2-col mobile), lightbox open/close/download
- [ ] Player management — invite form, player table
- [ ] Profile show/edit
- [ ] Navbar — desktop full nav, mobile hamburger open/close

---

## Summary: Files Modified (~35)

| Category | Files |
|---|---|
| Gemfile, Procfile.dev, bin/dev, .gitignore | 4 |
| New: `app/assets/tailwind/application.css` | 1 |
| Layouts (2) + Views (22) | 24 |
| Stimulus controllers | 2 |
| System specs | 5 |
| **Deleted:** `app/assets/stylesheets/app.css` | 1 |
