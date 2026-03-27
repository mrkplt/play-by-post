# Implementation Plan: Mobile Friendly Layout

**PRD:** `prd.json` v1.0.0
**Tech Spec:** `tech-spec.md`
**Date:** 2026-03-25
**Stories:** mobile-01 through mobile-05

---

## Phase 1: Integration Test Plan & Failing Tests

### Task 1.1 — Write integration test plan document
- **Sub-task 1.1.1** — Create `tests/integration/mobile_friendly_layout.md` describing the scenarios to test (nav toggle at 375px, composer at 375px, GM dashboard at 768px, post readability, email deep-links).

### Task 1.2 — Write failing integration tests (Capybara / system specs)
- **Sub-task 1.2.1** — Create `spec/system/mobile_nav_spec.rb`
  - Test: hamburger icon is visible at 375px viewport width
  - Test: nav links are hidden by default on mobile
  - Test: tapping hamburger opens the full-width menu
  - Test: tapping a menu link closes the menu
  - Test: tapping outside the menu closes it
  - Test: each nav link has a touch target ≥ 44px tall
- **Sub-task 1.2.2** — Create `spec/system/mobile_posts_spec.rb`
  - Test: scene post page has no horizontal scroll at 375px viewport
  - Test: body text font-size is at least 16px
  - Test: images in post content do not overflow their container
  - Test: reply indentation does not cause horizontal overflow at 375px
- **Sub-task 1.2.3** — Create `spec/system/mobile_composer_spec.rb`
  - Test: post composition form is visible and usable at 375px
  - Test: textarea is focusable without viewport zoom on iOS simulation
  - Test: Submit and Cancel buttons are fully visible (≥ 44px height)
  - Test: action buttons are stacked vertically on narrow screen
- **Sub-task 1.2.4** — Create `spec/system/tablet_gm_dashboard_spec.rb`
  - Test: GM dashboard panels are reachable at 768px viewport
  - Test: action buttons (create scene, edit character) are non-overlapping at 768px
  - Test: character and scene forms are operable at 768px
  - Test: no content is hidden based on screen size on tablet
- **Sub-task 1.2.5** — Create `spec/system/mobile_email_links_spec.rb`
  - Test: following a `game_scene_url` deep link at 375px renders the correct scene
  - Test: unauthenticated deep link redirects to sign-in, then back to target scene
  - Test: linked page renders without requiring zoom (viewport meta present)

---

## Phase 2: CSS — Base Styles & Global Image Safety

### Task 2.1 — Add global image safety rule to `app/assets/stylesheets/app.css`
- **Sub-task 2.1.1** — Read current `app.css` to understand existing structure and identify insertion point.
- **Sub-task 2.1.2** — Append the global `.post__content img` rule (not inside a media query):
  ```css
  .post__content img { max-width: 100%; height: auto; display: block; }
  ```

### Task 2.2 — Add hamburger button base styles (desktop-hidden) to `app.css`
- **Sub-task 2.2.1** — Append the `/* ─── Mobile Nav ─────────────────────────────────────── */` comment block.
- **Sub-task 2.2.2** — Add `.navbar__hamburger` base rule (`display: none`, sizing, colors).
- **Sub-task 2.2.3** — Add `.navbar__hamburger-bar` rule (bar appearance).
- **Sub-task 2.2.4** — Add `.navbar__link` base rule (colour + text-decoration).

### Task 2.3 — Add textarea auto-expand rule to `app.css`
- **Sub-task 2.3.1** — Append `.field textarea { resize: vertical; min-height: 6rem; }` in the base section.

---

## Phase 3: CSS — Mobile Breakpoint (`max-width: 767px`)

### Task 3.1 — Add mobile `@media (max-width: 767px)` block to `app.css`
- **Sub-task 3.1.1** — Hamburger visibility: `.navbar__hamburger { display: flex; }`
- **Sub-task 3.1.2** — Navbar flex-wrap and padding overrides.
- **Sub-task 3.1.3** — `.navbar__menu` full-width block layout; `:not([hidden])` display rule.
- **Sub-task 3.1.4** — `.navbar__actions` vertical column layout with `gap: 0`.
- **Sub-task 3.1.5** — Nav link touch targets: `min-height: 44px`, `line-height: 44px`, `display: block`, full width, border separators.
- **Sub-task 3.1.6** — `main` padding override for mobile.
- **Sub-task 3.1.7** — `.post__content` font-size and word-break rules.
- **Sub-task 3.1.8** — `.post--reply` indentation cap (`margin-left: 0.75rem`).
- **Sub-task 3.1.9** — `.post-composer-actions` column flex layout.
- **Sub-task 3.1.10** — Composer buttons full-width with `min-height: 44px`.
- **Sub-task 3.1.11** — Global `.btn`, `input[type="submit"]`, `button` touch target minimum.
- **Sub-task 3.1.12** — `.section__header` flex-wrap for stacking on narrow screens.
- **Sub-task 3.1.13** — `.table-responsive` overflow-x scroll rule; `table { min-width: 500px }`.
- **Sub-task 3.1.14** — `.auth-card` full-width margin/padding adjustments.
- **Sub-task 3.1.15** — Character card min/max-width override (`!important`).
- **Sub-task 3.1.16** — `.tree-node__title` and `.tree-node__meta` white-space normal.
- **Sub-task 3.1.17** — Textarea font-size `1rem` inside mobile media query (prevents iOS auto-zoom).

---

## Phase 4: CSS — Tablet Breakpoint (`768px – 1023px`) & Desktop Override

### Task 4.1 — Add tablet `@media (min-width: 768px) and (max-width: 1023px)` block to `app.css`
- **Sub-task 4.1.1** — Force `.navbar__menu { display: flex !important; }` and hide hamburger.
- **Sub-task 4.1.2** — `main` padding for tablet.
- **Sub-task 4.1.3** — `.section__header` flex-wrap to prevent overflow on tablet.
- **Sub-task 4.1.4** — `min-height: 44px` on buttons for tablet touch targets.

### Task 4.2 — Add desktop override `@media (min-width: 768px)` block to `app.css`
- **Sub-task 4.2.1** — Force `.navbar__menu { display: flex !important; }`.
- **Sub-task 4.2.2** — Force `.navbar__hamburger { display: none !important; }`.

---

## Phase 5: Stimulus Controller — Hamburger Menu Toggle

### Task 5.1 — Create `app/javascript/controllers/nav_controller.js`
- **Sub-task 5.1.1** — Scaffold file with `import { Controller } from "@hotwire/stimulus"`.
- **Sub-task 5.1.2** — Declare `static targets = ["menu", "toggle"]`.
- **Sub-task 5.1.3** — Implement `toggle()` method: flip `menuTarget.hidden`; update `aria-expanded` on `toggleTarget`.
- **Sub-task 5.1.4** — Implement `closeOnOutside(event)` method: if click is outside `this.element`, set `menuTarget.hidden = true` and reset `aria-expanded`.

### Task 5.2 — Register the controller (if not auto-loaded)
- **Sub-task 5.2.1** — Read `app/javascript/controllers/index.js` to confirm whether `stimulus-rails` eager-loading auto-discovers the new file.
- **Sub-task 5.2.2** — If manual registration is needed, add `import NavController from "./nav_controller"` and `application.register("nav", NavController)`.

---

## Phase 6: View — Responsive Navigation (`_navbar.html.erb`)

### Task 6.1 — Audit current navbar markup
- **Sub-task 6.1.1** — Read `app/views/layouts/_navbar.html.erb` to document current structure.

### Task 6.2 — Refactor navbar markup
- **Sub-task 6.2.1** — Add `data-controller="nav"` and `data-action="click@window->nav#closeOnOutside"` to `<nav class="navbar">`.
- **Sub-task 6.2.2** — Add hamburger `<button>` element with `class="navbar__hamburger"`, `aria-label`, `aria-expanded="false"`, `aria-controls="navbar-menu"`, `data-nav-target="toggle"`, `data-action="click->nav#toggle"`, and three `<span class="navbar__hamburger-bar">` children.
- **Sub-task 6.2.3** — Wrap existing nav links in `<div class="navbar__menu" id="navbar-menu" data-nav-target="menu" hidden>`.
- **Sub-task 6.2.4** — Ensure the existing `navbar__actions` div (user name, sign-out link) is nested inside `navbar__menu`.
- **Sub-task 6.2.5** — Verify all nav links receive or inherit `navbar__link` class for correct colour styling.

---

## Phase 7: View — Post Composer (`_composer.html.erb`)

### Task 7.1 — Audit current composer markup
- **Sub-task 7.1.1** — Read `app/views/posts/_composer.html.erb` to locate the action-row `div`.

### Task 7.2 — Add `post-composer-actions` CSS class
- **Sub-task 7.2.1** — Identify the `<div style="display:flex; gap:1rem; align-items:center; flex-wrap:wrap;">` action row.
- **Sub-task 7.2.2** — Add `class="post-composer-actions"` to that div while preserving the existing inline style.

---

## Phase 8: Views — Table Responsive Wrappers

### Task 8.1 — Wrap table in `app/views/player_management/show.html.erb`
- **Sub-task 8.1.1** — Read `player_management/show.html.erb` and identify `<table>` elements.
- **Sub-task 8.1.2** — Wrap each `<table>` in `<div class="table-responsive">...</div>`.

### Task 8.2 — Wrap table in `app/views/characters/show.html.erb`
- **Sub-task 8.2.1** — Read `characters/show.html.erb` and identify character-sheet `<table>` elements.
- **Sub-task 8.2.2** — Wrap each `<table>` in `<div class="table-responsive">...</div>`.

### Task 8.3 — Audit `app/views/scenes/index.html.erb` for tables
- **Sub-task 8.3.1** — Read `scenes/index.html.erb` to check whether it uses a `<table>`.
- **Sub-task 8.3.2** — If a table is present, wrap it in `<div class="table-responsive">`.

---

## Phase 9: Verify Email Deep Links (mobile-05)

### Task 9.1 — Audit mailer views and routing
- **Sub-task 9.1.1** — Read `app/views/layouts/mailer.html.erb` to confirm no viewport meta tag is present (not needed in email).
- **Sub-task 9.1.2** — Review the mailer view(s) that send notification links (`app/views/mailers/` or similar) to confirm URL helpers use `_url` (absolute) rather than `_path` (relative).
- **Sub-task 9.1.3** — Confirm `authenticate_user!` + `stored_location_for` is in place in the relevant controllers (no code change expected; this is verification only).

---

## Phase 10: Run Tests & Validate

### Task 10.1 — Run the new system/integration specs
- **Sub-task 10.1.1** — Execute `bundle exec rspec spec/system/mobile_nav_spec.rb` and confirm passing.
- **Sub-task 10.1.2** — Execute `bundle exec rspec spec/system/mobile_posts_spec.rb` and confirm passing.
- **Sub-task 10.1.3** — Execute `bundle exec rspec spec/system/mobile_composer_spec.rb` and confirm passing.
- **Sub-task 10.1.4** — Execute `bundle exec rspec spec/system/tablet_gm_dashboard_spec.rb` and confirm passing.
- **Sub-task 10.1.5** — Execute `bundle exec rspec spec/system/mobile_email_links_spec.rb` and confirm passing.

### Task 10.2 — Run full test suite to catch regressions
- **Sub-task 10.2.1** — Execute `bundle exec rspec` (all specs) and confirm no pre-existing tests are broken.

---

## Phase 11: Manual Browser Verification (Testing Plan Checklist)

### Task 11.1 — Start local development server
- **Sub-task 11.1.1** — Run `bin/rails server` and confirm the server starts on `localhost:3000`.

### Task 11.2 — Verify mobile layout in Chrome DevTools (375px — iPhone 13)
- **Sub-task 11.2.1** — Open Chrome DevTools → Device toolbar → iPhone 13 (375×812).
- **Sub-task 11.2.2** — Check: hamburger visible, desktop nav links hidden.
- **Sub-task 11.2.3** — Check: tapping hamburger opens full-width dropdown menu.
- **Sub-task 11.2.4** — Check: tapping a link closes the menu.
- **Sub-task 11.2.5** — Check: tapping outside the menu closes it.
- **Sub-task 11.2.6** — Navigate to a game scene page; confirm no horizontal scrollbar.
- **Sub-task 11.2.7** — Confirm body text is at least 16px.
- **Sub-task 11.2.8** — Confirm images in post content scale proportionally.
- **Sub-task 11.2.9** — Open post composer; confirm textarea is usable and Submit/Cancel buttons are fully visible with adequate touch targets.

### Task 11.3 — Verify tablet layout in Chrome DevTools (768px — tablet portrait)
- **Sub-task 11.3.1** — Set viewport to 768×1024.
- **Sub-task 11.3.2** — Check: hamburger is hidden, full nav links are visible.
- **Sub-task 11.3.3** — Navigate to GM dashboard; confirm all panels and action buttons are reachable and non-overlapping.
- **Sub-task 11.3.4** — Test create scene and edit character forms for full operability.

### Task 11.4 — Verify Samsung Galaxy layout (360px)
- **Sub-task 11.4.1** — Set viewport to 360px width (Galaxy S21).
- **Sub-task 11.4.2** — Repeat mobile checks from Task 11.2 at 360px.

---

## Phase 12: Linting

### Task 12.1 — Lint Ruby files
- **Sub-task 12.1.1** — Run `bundle exec rubocop` (or `bundle exec standardrb`) on changed `.erb` files and confirm no offences.

### Task 12.2 — Lint JavaScript
- **Sub-task 12.2.1** — Run `yarn lint` (or equivalent) on `nav_controller.js` if a JS linter is configured.

### Task 12.3 — Lint CSS
- **Sub-task 12.3.1** — Run `yarn stylelint` (or equivalent) on the appended `app.css` section if a CSS linter is configured.

---

## Acceptance Criteria Coverage Summary

| Story | Criteria | Covered By |
|---|---|---|
| mobile-01 | Hamburger visible <768px | Phase 3 (CSS) + Phase 6 (navbar) |
| mobile-01 | Full-width dropdown | Phase 3 (CSS) + Phase 5 (Stimulus) |
| mobile-01 | 44×44px touch targets | Phase 3 sub-tasks 3.1.5, 3.1.11 |
| mobile-01 | Menu closes on link / outside tap | Phase 5 sub-task 5.1.4 |
| mobile-02 | Reflow at 375px+ | Phase 3 (layout rules) |
| mobile-02 | 16px minimum body text | Phase 3 sub-task 3.1.7 |
| mobile-02 | Images scale proportionally | Phase 2 sub-task 2.1.2 |
| mobile-02 | Thread indentation collapses | Phase 3 sub-task 3.1.8 |
| mobile-03 | Composer usable at 375px | Phase 7 + Phase 3 sub-tasks 3.1.9–3.1.11 |
| mobile-03 | Textarea doesn't hide behind keyboard | Phase 2 sub-task 2.3.1 + Phase 3 sub-task 3.1.17 |
| mobile-03 | 44×44px Submit/Cancel | Phase 3 sub-task 3.1.10 |
| mobile-03 | Rich-text controls accessible | Phase 3 sub-task 3.1.9 (flex-wrap stacking) |
| mobile-04 | GM dashboard panels at 768px+ | Phase 4 (tablet breakpoint) |
| mobile-04 | Action buttons tappable, no overlap | Phase 4 sub-tasks 4.1.3–4.1.4 |
| mobile-04 | Forms operable on tablet | Phase 4 (native form elements; no JS override) |
| mobile-04 | No functionality hidden by screen size | Phase 4 sub-task 4.2.1 (menu always shown ≥768px) |
| mobile-05 | Email links open correct page | Phase 9 (routing audit; no code changes needed) |
| mobile-05 | Linked page renders in mobile viewport | All CSS phases |
| mobile-05 | Auth on email link | Phase 9 sub-task 9.1.3 (verification only) |
| mobile-05 | Deep links show correct post/scene | Phase 9 (existing controller logic unchanged) |
