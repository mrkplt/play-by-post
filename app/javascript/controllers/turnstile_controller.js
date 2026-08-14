import { Controller } from "@hotwired/stimulus"

// How long to wait for a reset widget to issue its replacement token before
// giving up and letting the submit proceed. The server rejects a blank token, so
// the user sees the form's own error rather than a silent failure; this only
// bounds the wait so a widget that never recovers cannot hang the form.
const TOKEN_TIMEOUT_MS = 10000
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
// that component gets the behaviour; a form signals a completed submit by
// dispatching `turnstile:reset` (see feedback_controller.js) rather than calling
// the Turnstile API itself.
export default class extends Controller {
  // Discard the spent token and request a fresh one. Safe to call when Turnstile
  // is absent (disabled in the test env, or the CDN script has not loaded yet) and
  // when the widget has not rendered.
  reset() {
    const widget = this.widget
    if (!widget) return

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

  // Resolves once the widget holds a token again, so a caller can submit without
  // racing the reset. Resolves immediately when there is no widget or no
  // Turnstile (nothing to wait for), and gives up after TOKEN_TIMEOUT_MS so a
  // broken widget degrades to a server-side rejection instead of a hung form.
  async ready() {
    if (!this.widget || !window.turnstile) return

    const deadline = Date.now() + TOKEN_TIMEOUT_MS
    while (Date.now() < deadline) {
      if (this.token) return
      await new Promise((resolve) => setTimeout(resolve, TOKEN_POLL_MS))
    }
  }

  get widget() {
    return this.element.querySelector(".cf-turnstile")
  }

  get token() {
    return this.element.querySelector("input[name='cf-turnstile-response']")?.value
  }
}
