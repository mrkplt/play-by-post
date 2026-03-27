# Mobile Friendly Layout — Integration Test Plan

## Overview
This plan covers manual and automated testing for the mobile-responsive layout
across all five user stories (mobile-01 through mobile-05).

---

## Story mobile-01: Responsive navigation menu

### Automated (spec/system/mobile_nav_spec.rb)
| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Hamburger icon visibility at 375px | `.navbar__hamburger` is visible |
| 2 | Nav menu hidden by default on mobile | `.navbar__menu` has `hidden` attribute |
| 3 | Tap hamburger opens full-width menu | `.navbar__menu` becomes visible after click |
| 4 | Tap a menu link closes the menu | `.navbar__menu` is hidden after link click |
| 5 | Tap outside menu closes it | `.navbar__menu` is hidden after outside click |
| 6 | Touch target height ≥ 44px for nav links | computed height ≥ 44px |

### Manual
- Open Chrome DevTools → iPhone 13 (375×812)
- Confirm hamburger icon renders in top-right of navbar
- Tap hamburger; verify full-width dropdown appears with all links
- Tap a link; menu closes, page navigates
- Tap outside the open menu; menu closes without navigating

---

## Story mobile-02: Readable and scrollable scene posts

### Automated (spec/system/mobile_posts_spec.rb)
| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | No horizontal scroll at 375px | `document.body.scrollWidth <= 375` |
| 2 | Body text font-size ≥ 16px | computed font-size ≥ 16px on `.post__content` |
| 3 | Images in posts do not overflow | image `offsetWidth <= parentElement.offsetWidth` |
| 4 | Reply indentation does not cause overflow | `.post--reply` no horizontal scroll |

### Manual
- Navigate to a scene page with several posts
- At 375px, confirm no horizontal scrollbar
- Zoom level is 100%; text is readable
- Post with an image: image scales within content width
- Nested reply: indentation is minimal, does not overflow

---

## Story mobile-03: Compose and submit posts from mobile

### Automated (spec/system/mobile_composer_spec.rb)
| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Composer form visible at 375px | form is in viewport |
| 2 | Textarea focusable (no zoom) | font-size ≥ 16px on textarea (prevents iOS zoom) |
| 3 | Submit button height ≥ 44px | computed min-height ≥ 44px |
| 4 | Buttons stack vertically on narrow screen | flex-direction is column |

### Manual
- At 375px open a scene page with a composer
- Tap the textarea; virtual keyboard appears; textarea remains visible
- Type content; Submit button is visible above the keyboard or scroll reaches it
- Submit and Cancel buttons each have at least 44px height

---

## Story mobile-04: GM tools accessible on tablet

### Automated (spec/system/tablet_gm_dashboard_spec.rb)
| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | GM dashboard panels reachable at 768px | panels visible without horizontal scroll |
| 2 | Action buttons non-overlapping at 768px | buttons' bounding boxes do not intersect |
| 3 | Scene creation form operable at 768px | form fields visible and submittable |
| 4 | No content hidden by screen size at 768px | `.navbar__menu` has `display:flex` |

### Manual
- Set DevTools viewport to 768×1024 (tablet portrait)
- Navigate to GM dashboard; confirm Create Scene, Edit Character buttons are visible
- Open create scene form; fill all fields; submit successfully
- Hamburger must not be visible; full nav visible

---

## Story mobile-05: Email notification links on mobile

### Automated (spec/system/mobile_email_links_spec.rb)
| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Deep link at 375px renders correct scene | page contains scene title |
| 2 | Unauthenticated deep link redirects to sign-in, then back | after sign-in lands on scene |
| 3 | Viewport meta present on linked page | `<meta name="viewport">` in `<head>` |

### Manual
- In dev mode, send a notification email and open the link on a physical iPhone or simulator
- Confirm page opens at correct scene without requiring zoom
- Sign out, then tap the link; confirm redirect to sign-in with return URL preserved
