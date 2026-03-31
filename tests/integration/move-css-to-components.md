# Move CSS to Components — Integration Test Plan

## Overview
CSS from the global `application.css` `@layer components` block is being co-located
with ViewComponents. This covers:
1. `Ui::BadgeComponent` replaces `.badge` / `.badge--*` classes
2. `Ui::BreadcrumbComponent` replaces `.breadcrumb` class
3. Sidebar CSS moved to `shared/sidebar_component.css` sidecar
4. Inline `style=""` attributes in component templates replaced with Tailwind utilities

---

## 1. BadgeComponent

### Automated (spec/components/ui/badge_component_spec.rb)
| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Default variant renders gray styles | span has slate-100 bg and slate-600 text classes |
| 2 | Yellow variant renders yellow styles | span has yellow-100 bg and yellow-800 text classes |
| 3 | Green variant renders green styles | span has green-100 bg and green-800 text classes |
| 4 | Blue variant renders blue styles | span has blue-100 bg and blue-800 text classes |
| 5 | Renders block content | span contains the text passed in block |
| 6 | All variants render without error | no raise_error for each variant |

### Manual
- Visit any scene page; confirm "Private", "Resolved", "Active" badges render with correct colours
- Visit games index; confirm "GM", "Player", "Former" badges display correctly
- Visit a character with archived/hidden status; confirm badges appear

---

## 2. BreadcrumbComponent

### Automated (spec/components/ui/breadcrumb_component_spec.rb)
| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Renders as a `<nav>` element | component output starts with `<nav>` tag |
| 2 | Applies correct Tailwind classes | nav has `text-sm`, `mb-4`, `text-slate-500` |
| 3 | Renders block content | nav contains passed content |

### Manual
- Visit Games show, Game edit, Scenes index, Scene show, Character show pages
- Confirm breadcrumb trail is visible in small muted text above the page heading
- Confirm breadcrumb links use the accent colour (gold/tan)

---

## 3. Sidebar CSS Sidecar

### Automated
- Existing sidebar system specs continue to pass (no new specs needed — CSS behaviour is visual)

### Manual
- At desktop width (>= 768px): sidebar is visible and fixed on the left
- At mobile width (375px): sidebar is hidden behind hamburger; opens on tap; backdrop appears
- Sidebar brand link, section labels, nav links, and user section all render correctly
- Active links show accent colour; hover states work

---

## 4. Inline Style Cleanup

### Automated
- Existing component specs continue to pass (no new specs needed)

### Manual
- Scene cards: title renders at correct size with no top/bottom margin
- Post items: "(edited)" label is italic; edit link is small; post image has top margin
- Gallery lightbox: Download/Delete buttons are small; thumbnail images fit container
- Sidebar: GM crown icon appears in accent colour

---

## 5. Regression

### Automated (run full suite)
```
bundle exec rspec
```
All existing tests must continue to pass.

### Manual smoke
- Sign in and navigate to a game
- Open and read a scene
- Post a reply
- View a character sheet
- Upload a file (if GM)
- Confirm no visual regressions on desktop and mobile
