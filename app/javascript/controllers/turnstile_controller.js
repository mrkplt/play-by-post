import { Controller } from "@hotwired/stimulus"

// How long to wait for a reset widget to issue its replacement token before
// giving up and letting the submit proceed. The server rejects a stale or blank
// token, so the user sees the form's own error rather than a silent failure;
// this only bounds the wait so a widget that never recovers cannot hang the form.
const TOKEN_POLL_MS = 100

// Owns the lifecycle of one Cloudflare Turnstile widget.
//
// Turnstile tokens are single-use: once a token has been sent to siteverify it is
// spent, and replaying it is rejected as `timeout-or-duplicate`. A form that
// navigates on submit gets a fresh widget with the next page load and needs
// nothing here. A form submitted via fetch does not — it keeps the spent token in
// the DOM, so every submit after the first fails until the widget is reset.
//
// Reset is not instantaneous, which is the subtlety this controller exists to
// hide. `turnstile.reset()` clears the response synchronously and swaps in a new
// iframe; the replacement token arrives later over postMessage. So a form that
// resets and immediately submits again would send an *empty* token and be
// rejected — the original bug wearing a different hat. `ready()` is what callers
// await to avoid that.
//
// This controller is rendered by Ui::TurnstileWidgetComponent, so any form using
// that component has it available. A form's own controller drives it — `reset()`
// after a submit, `await ready()` before the next one (see feedback_controller.js
// for the pattern) — and never touches the Turnstile API itself.
export default class extends Controller {
  // Declared as a value so the component owns the default and a spec can shorten
  // it; nothing else varies it at runtime.
  static values = { timeout: { type: Number, default: 10000 } }

  // Discard the spent token and request a fresh one. Safe to call when Turnstile
  // is absent (disabled in the test env, or the CDN script has not loaded yet) and
  // when the widget has not rendered.
  reset() {
    const widget = this.widget
    if (!widget) return

    // Remember what was spent so `ready` can insist on a genuinely different
    // token rather than accepting whatever happens to be sitting in the input.
    this.spentToken = this.token

    try {
      window.turnstile?.reset(widget)
    } catch (error) {
      // Turnstile throws when the container or widget cannot be found — the one
      // case that does not recover on its own, since nothing re-runs the
      // challenge. Surface it rather than leaving a permanently tokenless form
      // failing with the server's generic error and no explanation anywhere.
      console.warn("Turnstile reset failed; the widget may not have rendered.", error)
    }
  }

  // Resolves once the widget holds a token that is not the spent one, so a caller
  // can submit without racing the reset. Waiting for a *different* token rather
  // than merely a present one matters when reset silently fails to take: the old
  // token would still be in the input, and accepting it would replay a spent
  // token — the very bug this controller exists to prevent.
  //
  // Resolves immediately when there is nothing to wait for (no widget, or no
  // Turnstile). On giving up it discards the spent token rather than letting the
  // submit carry it: a stale token might still be *accepted* by the server, which
  // would defeat the single-use guarantee, whereas a blank one is refused
  // outright and surfaces as the form's own error.
  async ready() {
    if (!this.widget || !window.turnstile) return

    const deadline = Date.now() + this.timeoutValue
    while (Date.now() < deadline) {
      const token = this.token
      if (token && token !== this.spentToken) return

      await new Promise((resolve) => setTimeout(resolve, TOKEN_POLL_MS))
    }

    this.clearStaleToken()
  }

  // Only clears when the input still holds the spent value — a token that arrived
  // late, between the last poll and here, must survive.
  clearStaleToken() {
    const input = this.element.querySelector("input[name='cf-turnstile-response']")
    if (input && input.value === this.spentToken) input.value = ""
  }

  get widget() {
    return this.element.querySelector(".cf-turnstile")
  }

  get token() {
    return this.element.querySelector("input[name='cf-turnstile-response']")?.value
  }
}
