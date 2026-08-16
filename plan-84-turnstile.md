# Plan: Turnstile token reset (#84) + invisible widget (#82)

Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/84
Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/82

## Goal

Fix two defects introduced with the Turnstile implementation (#213), both living in
the same files:

- **#84** — submitting feedback twice in a row fails. Turnstile tokens are single-use;
  the modal submits via `fetch` and never navigates, so the second submit replays a
  spent token, Cloudflare returns `timeout-or-duplicate`, `verify_turnstile!` 403s, and
  the modal shows its generic error banner.
- **#82** — the Turnstile widget renders as a persistent visible box on the feedback
  modal and the sign-in form. It should not be visible unless it requires interaction.

## Decisions (settled, do not re-open)

- **#82 is solved by switching the widget to the Invisible type in the Cloudflare
  dashboard**, not by an `appearance` attribute or CSS. Owner's call. Code side is
  limited to whatever the invisible type requires; the visibility behaviour itself is
  dashboard configuration.
- **The reset fix is universal, made at the component level** — not patched into the
  feedback Stimulus controller alone. `Ui::TurnstileWidgetComponent` is the single
  place both call sites (`feedback_modal_component.html.erb:28`,
  `users/sessions/new.html.erb:17`) route through, so the behaviour belongs there.

## Root cause detail

`app/javascript/controllers/feedback_controller.js:67` — `reset()` clears the textarea,
error banner, and panel visibility, but never resets the Turnstile widget, so
`cf-turnstile-response` still holds the spent token from the previous submit.

Cloudflare docs confirm: tokens are single-use, a replayed token is rejected as
`timeout-or-duplicate`, and `turnstile.reset(widgetId)` must be called after the request
completes before allowing a retry. With implicit (`cf-turnstile` class) rendering,
`turnstile.reset()` with no argument resets the last-created widget — no explicit
`render()` call is required.

## Tasks

- [ ] Reproduce the double-submit failure (system spec or manual against local).
- [ ] Add token-reset behaviour at the component level so every widget call site gets it.
- [ ] Wire the feedback modal's post-submit path to trigger the reset (both success and
      failure — a failed submit also spends the token).
- [ ] Handle the Invisible widget type: confirm what the component must emit, and that
      an invisible widget still yields a token for the server-side check.
- [ ] Specs: component spec for the new behaviour; request/system coverage for a second
      consecutive feedback submit succeeding.
- [ ] Update `docs/CONFIGURATION.md` if the widget type / keys guidance changes.
- [ ] Gates: `.mutant.yml` registration is already in place for the component; keep
      coverage above floor for every touched file.

## Open questions

- Does the sign-in form need any change at all? It uses `data: { turbo: false }` and
  fully navigates, so it gets a fresh widget per render. The universal component-level
  fix should be inert there rather than dead code — verify it is.
- Invisible widget type is dashboard-side; confirm whether the test/dev always-pass keys
  behave the same way, since `Turnstile.enabled?` is false in test.
