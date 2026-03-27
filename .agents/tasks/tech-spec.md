# Technical Specification: Mobile Friendly Layout

**PRD Version:** 1.0.0
**Date:** 2026-03-25
**Stories:** mobile-01 through mobile-05

---

## 1. Architecture Overview

The application is a **Rails 8** app using **Hotwire (Turbo + Stimulus)**, a custom CSS stylesheet (`app.css`), and **Propshaft** for asset delivery. There is no CSS framework (no Bootstrap, no Tailwind). All styling is hand-written vanilla CSS.

The mobile work is **purely frontend**: CSS media queries + a new Stimulus controller for the hamburger menu. No backend changes, no database migrations, no new routes.

### Approach

1. Add `@media` breakpoint rules to `app/assets/stylesheets/app.css` covering:
   - **Mobile**: `max-width: 767px`
   - **Tablet**: `768px – 1023px`
2. Add a hamburger menu to `app/views/layouts/_navbar.html.erb` hidden on desktop, visible on mobile.
3. Create a new Stimulus controller `app/javascript/controllers/nav_controller.js` to toggle the mobile menu open/closed.
4. Audit and patch individual view files where inline styles create layout problems on narrow screens.
5. Ensure the `<textarea>` in the post composer grows with content (CSS `field-sizing` or `resize: vertical`).

No new pages, no new routes, no database changes.

---

## 2. Detailed Component Design

### 2.1 Viewport Meta Tag

The layout already includes:
```html
<meta name="viewport" content="width=device-width,initial-scale=1">
```
No change needed here.

---

### 2.2 Responsive Navigation (mobile-01)

#### Current state
`_navbar.html.erb` is a two-element flexbox row (brand + actions). On narrow screens the actions text wraps poorly and touch targets are small.

#### Changes to `_navbar.html.erb`

Add a hamburger `<button>` element (hidden on desktop via CSS, visible on mobile) and wrap the nav links in a collapsible container:

```erb
<nav class="navbar" data-controller="nav" data-action="click@window->nav#closeOnOutside">
  <div class="navbar__brand">
    <%= link_to "Play by Post", root_path %>
  </div>

  <!-- Hamburger: visible only on mobile -->
  <button class="navbar__hamburger"
          aria-label="Toggle navigation"
          aria-expanded="false"
          aria-controls="navbar-menu"
          data-nav-target="toggle"
          data-action="click->nav#toggle">
    <span class="navbar__hamburger-bar"></span>
    <span class="navbar__hamburger-bar"></span>
    <span class="navbar__hamburger-bar"></span>
  </button>

  <!-- Nav menu: on desktop always visible; on mobile hidden until toggled -->
  <div class="navbar__menu" id="navbar-menu" data-nav-target="menu" hidden>
    <div class="navbar__actions">
      <% if user_signed_in? %>
        <%= link_to current_user.display_name || current_user.email.split("@").first,
            edit_profile_path, class: "navbar__user" %>
        <%= link_to "Sign out", destroy_user_session_path, class: "navbar__link" %>
      <% end %>
    </div>
  </div>
</nav>
```

**Key behaviour:**
- On desktop (≥768px): `.navbar__hamburger` is `display:none`; `.navbar__menu` is `display:flex` regardless of `hidden` attribute.
- On mobile (<768px): `.navbar__hamburger` is visible; `.navbar__menu[hidden]` is `display:none`; when JS removes `hidden`, menu slides in as a full-width block below the brand row.
- Clicking outside or selecting a link closes the menu.

---

### 2.3 Stimulus Controller: `nav_controller.js`

**File:** `app/javascript/controllers/nav_controller.js`

```javascript
import { Controller } from "@hotwire/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle"]

  toggle() {
    const isOpen = !this.menuTarget.hidden
    this.menuTarget.hidden = isOpen
    this.toggleTarget.setAttribute("aria-expanded", String(!isOpen))
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.hidden = true
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }
}
```

Register in `app/javascript/controllers/index.js` (standard Stimulus auto-load handles this if using `stimulus-rails` eager loading).

---

### 2.4 CSS Changes (`app/assets/stylesheets/app.css`)

All additions go at the **bottom** of the existing file in a clearly delimited section.

#### 2.4.1 Hamburger button base styles (desktop-hidden)

```css
/* ─── Mobile Nav ─────────────────────────────────────── */
.navbar__hamburger {
  display: none;
  flex-direction: column;
  justify-content: center;
  gap: 5px;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.5rem;
  min-width: 44px;
  min-height: 44px;
  color: #f8fafc;
}
.navbar__hamburger-bar {
  display: block;
  width: 22px;
  height: 2px;
  background: #f8fafc;
  border-radius: 2px;
}
.navbar__link { color: #f8fafc; text-decoration: none; }
```

#### 2.4.2 Mobile breakpoint (`max-width: 767px`)

```css
@media (max-width: 767px) {
  /* Hamburger visible */
  .navbar__hamburger { display: flex; }

  /* Menu becomes full-width block below brand row */
  .navbar {
    flex-wrap: wrap;
    padding: 0.75rem 1rem;
  }
  .navbar__menu {
    width: 100%;
    padding: 0.5rem 0;
    border-top: 1px solid #334155;
  }
  /* Remove hidden override — let JS control visibility */
  .navbar__menu:not([hidden]) { display: block; }

  .navbar__actions {
    flex-direction: column;
    align-items: flex-start;
    gap: 0;
  }
  .navbar__actions a,
  .navbar__actions .navbar__user,
  .navbar__actions .navbar__link {
    display: block;
    padding: 0.75rem 0;
    min-height: 44px;
    line-height: 44px;
    width: 100%;
    border-bottom: 1px solid #334155;
    font-size: 1rem;
  }

  /* Layout */
  main { padding: 1rem 0.75rem; }

  /* Posts: readable body text, no overflow */
  .post__content {
    font-size: 1rem;
    word-break: break-word;
    overflow-wrap: break-word;
  }
  .post__content img {
    max-width: 100%;
    height: auto;
  }

  /* Threaded indentation: cap depth on narrow screens */
  .post--reply { margin-left: 0.75rem; }
  .post--reply .post--reply { margin-left: 0.75rem; }

  /* Composer form */
  .post-composer-actions {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
  }
  .post-composer-actions .btn,
  .post-composer-actions input[type="submit"] {
    width: 100%;
    text-align: center;
    min-height: 44px;
    font-size: 1rem;
  }

  /* Buttons: ensure minimum touch targets */
  .btn, input[type="submit"], button {
    min-height: 44px;
    padding: 0.6rem 1.25rem;
  }

  /* Section headers: stack on very small screens */
  .section__header {
    flex-wrap: wrap;
    gap: 0.5rem;
  }
  .section__header .btn { font-size: 0.9rem; }

  /* Tables: allow horizontal scroll within a wrapper */
  .table-responsive { overflow-x: auto; -webkit-overflow-scrolling: touch; }
  table { min-width: 500px; }

  /* Auth card: full-width on mobile */
  .auth-card {
    margin: 1.5rem auto;
    padding: 1.25rem;
  }

  /* Character cards: stack vertically */
  .card[style*="min-width:160px"] { min-width: 100% !important; max-width: 100% !important; }

  /* Scene tree: allow node titles to wrap */
  .tree-node__title { white-space: normal; }
  .tree-node__meta { white-space: normal; margin-left: 0.5rem; }
}
```

#### 2.4.3 Tablet breakpoint (`768px – 1023px`) — mobile-04

```css
@media (min-width: 768px) and (max-width: 1023px) {
  /* Desktop menu always visible */
  .navbar__menu { display: flex !important; }
  .navbar__hamburger { display: none; }

  main { padding: 1.25rem 1.5rem; }

  /* Ensure GM dashboard panels don't overflow */
  .section__header { flex-wrap: wrap; gap: 0.5rem; }

  /* Buttons: reachable touch targets */
  .btn, input[type="submit"], button { min-height: 44px; }
}

/* Desktop: always show menu, hide hamburger */
@media (min-width: 768px) {
  .navbar__menu { display: flex !important; }
  .navbar__hamburger { display: none !important; }
}
```

---

### 2.5 Post Composer Textarea Auto-Expand (mobile-03)

The `<textarea>` in `_composer.html.erb` should expand as the user types. Add to CSS:

```css
.field textarea {
  resize: vertical;
  min-height: 6rem;
}

@media (max-width: 767px) {
  .field textarea {
    font-size: 1rem; /* prevents iOS auto-zoom on focus */
  }
}
```

The `font-size: 1rem` on textarea (≥16px) prevents iOS Safari from auto-zooming into the input when the user focuses it.

Also add a CSS class to the composer actions div in `_composer.html.erb`:

```erb
<div style="display:flex; gap:1rem; align-items:center; flex-wrap:wrap;" class="post-composer-actions">
```

---

### 2.6 Image Safety in Posts (mobile-02)

Post content is rendered from markdown via the `render_markdown` helper. Images inside post content can overflow. Add globally:

```css
.post__content img { max-width: 100%; height: auto; display: block; }
```

This goes in the base post section (not just inside a media query) as a best practice.

---

### 2.7 Scrollable Tables (mobile-02, mobile-04)

Tables in views like player management and character sheets risk horizontal overflow. Wrap `<table>` elements in:

```erb
<div class="table-responsive">
  <table>...</table>
</div>
```

Affected views:
- `app/views/player_management/show.html.erb`
- `app/views/characters/show.html.erb` (character sheet table)
- `app/views/scenes/index.html.erb` (if table-based)

---

### 2.8 Email Notification Links (mobile-05)

Email links use standard Rails URL helpers (`game_scene_url(...)`) which already produce absolute deep-link URLs. No changes are needed to routing or mailer templates.

The fix here is ensuring the **destination pages** render correctly on mobile — which is handled by the CSS changes above.

Verify the following in the mailer layout (`app/views/layouts/mailer.html.erb`):
- A `<meta name="viewport">` tag is not needed in email HTML (email clients ignore it), but the linked pages are fully responsive post-implementation.
- Authentication: Devise sessions are cookie-based. If a user follows a link while not logged in, they are redirected to sign-in and then back to the target (standard `authenticate_user!` + `stored_location_for` behaviour). No changes needed.

---

## 3. API Definitions

No new API endpoints are required. All changes are frontend-only.

---

## 4. Data Model Changes

None. This feature is entirely presentational.

---

## 5. File Change Summary

| File | Change Type | Description |
|---|---|---|
| `app/assets/stylesheets/app.css` | Modify | Add mobile/tablet `@media` queries, hamburger styles, touch target rules, image safety, textarea fix |
| `app/views/layouts/_navbar.html.erb` | Modify | Add hamburger button, wrap links in `navbar__menu` div, add Stimulus data attributes |
| `app/javascript/controllers/nav_controller.js` | Create | Stimulus controller for hamburger toggle and close-on-outside-click |
| `app/views/posts/_composer.html.erb` | Modify | Add `post-composer-actions` CSS class to action row div |
| `app/views/player_management/show.html.erb` | Modify | Wrap table in `div.table-responsive` |
| `app/views/characters/show.html.erb` | Modify | Wrap character sheet table in `div.table-responsive` |

---

## 6. Security Considerations

- **No new input surfaces.** All changes are CSS and a toggle controller.
- **No XSS risk.** The Stimulus controller only manipulates the `hidden` attribute on an element already in the DOM.
- **`aria-expanded`** is set correctly by the controller to avoid screen reader confusion.
- **No new routes or server-side logic** means no new attack surface.
- Existing Devise authentication flow for email deep links is unchanged and correct.

---

## 7. Acceptance Criteria Mapping

| Story | Acceptance Criteria | Implementation |
|---|---|---|
| mobile-01 | Nav collapses to hamburger <768px | `@media` + `nav_controller.js` |
| mobile-01 | Full-width dropdown/slide-out | `.navbar__menu` block layout in mobile media query |
| mobile-01 | 44×44px touch targets | `min-height: 44px` on all nav links and buttons |
| mobile-01 | Menu closes on link tap / outside tap | `closeOnOutside` in `nav_controller.js` + Turbo navigation naturally triggers page load |
| mobile-02 | Reflow at 375px+ | Fluid `main` layout + `max-width: 900px` already fluid; no fixed widths |
| mobile-02 | 16px minimum body text | Body already `1rem`; added `font-size: 1rem` override on post content |
| mobile-02 | Images scale proportionally | `img { max-width: 100%; height: auto }` in `.post__content` |
| mobile-02 | Thread indentation collapses | `.post--reply` capped at `0.75rem` indent on mobile |
| mobile-03 | Composer usable at 375px | Full-width stacked button layout via `.post-composer-actions` |
| mobile-03 | Textarea doesn't hide behind keyboard | `resize: vertical` + native browser scroll behaviour; no fixed heights |
| mobile-03 | 44×44px Submit/Cancel | `min-height: 44px` on `.btn` at mobile breakpoint |
| mobile-03 | Rich-text (markdown) controls accessible | Preview button and OOC checkbox already in flex-wrap row; stacked on mobile |
| mobile-04 | GM dashboard panels at 768px+ | Tablet breakpoint ensures layout holds; `section__header` flex-wrap for overflow prevention |
| mobile-04 | Action buttons tappable, no overlap | `min-height: 44px` global; `flex-wrap: wrap` on header rows |
| mobile-04 | Forms operable on tablet touch | Standard `<form>` elements are touch-native; no JS overrides |
| mobile-04 | No functionality hidden by screen size | CSS only hides hamburger/menu toggle; all content remains in DOM |
| mobile-05 | Email links open correct page | Existing routing unchanged; deep links work |
| mobile-05 | Linked page renders correctly in mobile viewport | All pages covered by CSS changes above |
| mobile-05 | Auth on email link | Devise `authenticate_user!` + stored location redirect unchanged |
| mobile-05 | Deep links show correct post/scene | Existing controller logic unchanged |

---

## 8. Testing Plan Notes

Integration tests (Capybara + Playwright) should cover:

1. **Nav toggle**: At 375px viewport, hamburger visible; click opens menu; click outside closes.
2. **Nav links reachable**: All navbar links in the open mobile menu are within bounds (>= 44px tall).
3. **Scene page at 375px**: No horizontal scroll; post content wraps; images don't overflow.
4. **Composer at 375px**: Textarea focusable; submit button fully visible without scrolling past it; no iOS zoom.
5. **GM dashboard at 768px**: All buttons visible and non-overlapping on tablet portrait.
6. **Email link**: Following a `game_scene_url(...)` link while unauthenticated redirects to sign-in then back to correct scene.
