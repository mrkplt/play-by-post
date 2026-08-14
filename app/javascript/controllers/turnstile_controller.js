import { Controller } from "@hotwired/stimulus"

// Owns the lifecycle of one Cloudflare Turnstile widget.
//
// Turnstile tokens are single-use: once a token has been sent to siteverify it is
// spent, and replaying it is rejected as `timeout-or-duplicate`. A form that
// navigates on submit gets a fresh widget with the next page load and needs
// nothing here. A form submitted via fetch does not — it keeps the spent token in
// the DOM, so every submit after the first fails until the widget is reset.
//
// This controller is rendered by Ui::TurnstileWidgetComponent, so any form using
// that component gets the behaviour; a form signals a completed submit by
// dispatching `turnstile:reset` (see feedback_controller.js) rather than calling
// the Turnstile API itself.
export default class extends Controller {
  // Discard the spent token and request a fresh one. Safe to call when Turnstile
  // is absent (disabled in the test env, or the CDN script has not loaded yet) and
  // when the widget has not rendered — reset throws on an unrendered widget, and a
  // failure to refresh must not take down the form the widget is attached to.
  reset() {
    const widget = this.element.querySelector(".cf-turnstile")
    if (!widget) return

    try {
      window.turnstile?.reset(widget)
    } catch {
      // An unrendered or already-reset widget is not an error worth surfacing:
      // the next submit re-runs the challenge anyway.
    }
  }
}
