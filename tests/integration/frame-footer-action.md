# Frame footer action reachability (Fizzy #125)

## Bug

On the "All Scenes" screen (`/games/:slug/scenes`) the **New Scene** button did
not respond without multiple taps; on a tall scene tree it fell off the bottom of
the screen. Root cause was the shared `MobileFrameComponent` frame convention, not
this one screen:

- `.app-frame` was `min-h-[96vh] flex flex-col` — it grew taller than the viewport
  with no scroll containment.
- The footer was `sticky bottom-0`, so it pinned to the bottom of the (over-tall)
  *frame*, below the fold — not to the viewport.
- On mobile, a static `vh`/min-height also ignored the browser address bar
  shrinking the visible area, pushing the footer further out of reach.

All ~36 screens compose this frame, so the fix lands once in the shared component.

## Fix

- `.app-frame`: `h-[100dvh] flex flex-col … overflow-hidden` — exactly one
  (dynamic) viewport tall, clips its own overflow.
- `.app-body`: `flex-1 min-h-0 overflow-y-auto …` — the single scroll region
  (`min-h-0` lets the flex child shrink below content height so it actually
  scrolls).
- Footer: drop `sticky bottom-0`, add `shrink-0`. As the last child of a
  non-scrolling flex column it is naturally pinned in view, and `sticky` would be
  clipped by the frame's `overflow-hidden`.

## Automated coverage

- `spec/components/shared/mobile_frame_component_spec.rb` — footer is a
  `shrink-0` non-sticky last child; body is the content region.
- `spec/system/frame_footer_action_spec.rb` — at **both** viewports (375×812 and
  1280×900), with a 30-scene tree that overflows the viewport:
  - the frame's computed `overflow-y` is `hidden` and the body's is `auto`;
  - `click_on "New Scene"` navigates (button reachable without the test scrolling);
  - the footer's `getBoundingClientRect().bottom` is within the viewport height.
  - Verified to **fail on the pre-fix CSS** (overflow not hidden; footer bottom
    below the viewport) and pass after — so it captures the regression.

## Manual verification

1. Sign in as a GM; open a game with many scenes so "All Scenes" overflows.
2. Phone viewport: the New Scene button sits at the bottom, always visible; the
   scene list scrolls beneath it; one tap opens the new-scene form.
3. Desktop viewport (≥1024px): same, with the footer centered at reading width.
4. Screens with no footer (a scene show page) still scroll normally with no
   clipped content.
