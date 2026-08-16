# Tasks: Turnstile token reset (#84)

Plan: `plan-84-turnstile.md`
Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/84
PR: https://github.com/mrkplt/play-by-post/pull/227

**Scope note:** #82 (invisible widget) is **deferred** — it is a Cloudflare dashboard
change the owner will make, not code. Only #84 is in scope for this run.

**Design decision (owner, this session):** the reset is wired via a new Stimulus
controller owned by `Ui::TurnstileWidgetComponent`, so every call site inherits it.
`feedback_controller.js` dispatches an event and never touches the Turnstile API.

## Tasks

- [x] **1. Failing system spec** — `spec/system/feedback_spec.rb` "with Turnstile
      enabled" forces `Turnstile.enabled?` on so the real widget renders, and stubs
      siteverify to refuse a blank token and reject a replayed one. Now three examples
      (the double submit, the async wait, the stuck widget); each verified to fail when
      the behaviour it covers is removed. (commits `cecee4f`, `a9678db`, `9d01e72`)
- [x] **2. `turnstile_controller.js`** — new Stimulus controller owning the widget
      lifecycle: `reset()` spends the token and starts a refresh; `ready()` waits for a
      genuinely different one and discards a stale one on timeout. Guarded on a missing
      widget and a missing API. (commits `01cc74f`, `a9678db`, `9d01e72`)
- [x] **3. Wire the component** — `Ui::TurnstileWidgetComponent` renders a wrapper
      carrying `data-controller`, with the widget div nested inside so Turnstile's own
      iframe swap never clobbers the controller's element. Both call sites inherit it.
      (commits `01cc74f`, `a9678db`)
- [x] **4. Drive it from the feedback modal** — `feedback_controller.js` awaits
      `ready()` before the fetch and calls `reset()` in a `finally`, so the refresh runs
      on success *and* failure. (commits `01cc74f`, `a9678db`)
- [x] **5. Component spec** — examples covering the wrapper, the widget nesting, and
      the data-action separation. 14 examples green. (commits `01cc74f`, `a9678db`)
- [x] **6. Gates** — rubocop, srb tc, view-layering, design-tokens, mutant-registration
      all OK. Full suite 2706 examples / 0 failures. `--check` all green; changed
      component at 100% line and branch.
- [x] **7. Verify in browser** — done via the project's Playwright driver rather than
      interactive Chrome (extension not connected). Controlled before/after run proves
      the fix: without it the second submit replays `token-0`; with it the submits carry
      `token-0` then `token-1` and both succeed.

## Decisions

**Deviations from the plan**

- **#82 not implemented.** Owner deferred it: the chosen approach (Invisible widget
  type) is Cloudflare dashboard configuration, not code. Flagged to the owner that the
  sitekey is shared with sign-in and that Invisible widgets stay hidden *even when a
  challenge is required*, so a bot-flagged user could hit a silent sign-in failure.
- **Reset wiring settled by asking, not guessing.** The plan said "component level" but
  the component renders only markup. Owner chose a Stimulus controller owned by the
  component over patching `feedback_controller.js` directly.
- **Extra commit `6b873af`** (not in the original checklist): the JS controller name
  mirrors a Ruby constant with nothing failing fast on drift — the widget is absent in
  the test env and the system spec runs only in the heavy tier. Added a fast-tier
  assertion pinning them, verified by flipping the JS constant.

**Problems found during the run**

- **`data-action` collision.** Turnstile reads it as the challenge label, Stimulus as an
  event binding. Resolved by putting the controller on a wrapper with the widget nested
  inside.
- **Bubbling direction.** The widget sits *inside* the form, so an event dispatched on
  the form travels away from it. Initially wired wrong; corrected, and later dropped
  entirely in favour of calling the controller directly.
- **First system spec attempt was invalid.** It appended a second
  `cf-turnstile-response` input, but the real script owns its own and `FormData`
  serialized that one. Rewritten to write into the real input.

**Code review findings and disposition** (reviewer agent, commits 01cc74f + cecee4f)

- **HIGH — reset is async; submit not gated on the new token. ACCEPTED, fixed in
  `a9678db`.** Verified independently rather than taken on trust: fetched Cloudflare's
  `api.js` and confirmed `reset()` sets `h.response=void 0` and swaps the iframe
  (`replaceChild(F,L)`), with the token written later by `ei()` (`n.value=r`). Then
  observed it in a real browser — the input reads empty immediately after reset and
  repopulates a moment later. The first fix therefore converted a deterministic failure
  into an intermittent one. `ready()` now waits for the replacement, bounded at 10s.
- **HIGH — spec stub inverted real behaviour. ACCEPTED, fixed in `a9678db`.** The stub
  repopulated the token synchronously, so it would have passed with the race present.
  It now clears and repopulates on a timer, plus a second example asserting the tokens
  siteverify actually received. Confirmed both examples fail when the `await` is removed.
- **MEDIUM — bare `catch {}` hides the unrecoverable case. ACCEPTED, fixed in
  `a9678db`.** Turnstile throws when the container/widget cannot be found, which is
  exactly the case that never recovers. Now `console.warn`s instead of discarding.
- **LOW — `bubbles` omission correct, worth a comment. MOOT.** The event-dispatch
  mechanism was replaced by a direct controller call in `a9678db`.
- **LOW — constant duplication acceptable. AGREED**, and already guarded by `6b873af`.
- **Security — no weakening. AGREED.** Enforcement stays server-side, each token is
  verified once, and a bot could always reload the page to get a fresh token.

**Evaluator findings and disposition** (independent agent, after `a9678db`)

The evaluator re-ran the deletion experiments itself rather than trusting the commit
messages, and confirmed both halves of the fix are load-bearing.

- **`ready()` waited for *a* token, not a *changed* one. ACCEPTED, fixed in `9d01e72`.**
  If reset silently failed to take, the spent token was still in the input, so the wait
  returned immediately and replayed it — the original bug in the one case the reset
  exists to cover. Now waits for a differing token and, on giving up, discards the stale
  value so the server refuses a blank token rather than possibly accepting a stale one.
  Two wrong turns getting there, both worth recording: the first attempt at a spec set a
  stale value the *live* widget promptly overwrote (so the fix looked broken when it was
  the test that was wrong — diagnosed by reading the controller instance in the browser),
  and the second revealed that the timeout path fell through and submitted the stale
  token anyway.
- **Stale comments describing the removed `turnstile:reset` event. ACCEPTED, fixed in
  `9d01e72`.** Two comments and the wrapper rationale described an architecture
  `a9678db` had deleted, on the first files a maintainer reads.
- **Checklist stale relative to `a9678db`. ACCEPTED** — corrected below.
- **Universality regressed slightly. ACKNOWLEDGED, not changed.** Moving from an event
  binding to a direct controller call means a new fetch-submitted form must copy ~2 lines
  (`await ready()`, `reset()`) rather than inheriting them from markup. The trade was
  forced: an event cannot be awaited, and awaiting is what closes the race. A Stimulus
  outlet or shared mixin would recover it; noted as a follow-up, not done here.
- **No JS unit harness, so `ready()`'s timeout branch is only covered through system
  specs. ACKNOWLEDGED** — structural limit of the project, not an omission. The timeout
  path does now execute in a test (the stuck-widget example).
- **No in-flight submit guard (double-click fires two submits). ACKNOWLEDGED,
  pre-existing**, same visible symptom; not introduced by this work and out of scope.

**Surfaced but deliberately not fixed here**

- **`/feedback` has no rate limiting at all** — nothing in `rack_attack.rb`, no
  controller `rate_limit`, no model constraint. Turnstile is its only abuse guard.
  Pre-existing and outside #84; raised to the owner as a candidate card.
- **One surviving mutant** (`content_tag(:div, "")` → `nil`) is equivalent — both render
  `<div></div>`. Left per the project's field notes. Aggregate 98.33%, floor 80%.

## Out of scope

- #82 invisible widget type (dashboard-side, owner).
- Any change to `TurnstileVerifier` / `TurnstileVerification` server-side logic — the
  server behaviour is correct; the bug is entirely client-side token reuse.
