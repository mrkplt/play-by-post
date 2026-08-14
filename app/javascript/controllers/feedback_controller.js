import { Controller } from "@hotwired/stimulus"

// Mirrors Ui::TurnstileWidgetComponent::STIMULUS_CONTROLLER.
const TURNSTILE_CONTROLLER = "turnstile"

// The feedback modal, opened from the nav drawer. On open it captures the path
// (with any query parameters) of the page the user is on into a hidden field.
// Submitting posts via fetch so
// the page never navigates — on success the modal swaps to an in-place "thanks"
// panel; the user stays exactly where they were. Cancel/backdrop/Escape dismiss.
export default class extends Controller {
  static targets = ["modal", "field", "url", "error", "formPanel", "successPanel"]

  open() {
    this.reset()
    this.urlTarget.value = `${window.location.pathname}${window.location.search}`
    this.modalTarget.hidden = false
    document.body.style.overflow = "hidden"
    this.fieldTarget.focus()
  }

  close() {
    this.modalTarget.hidden = true
    document.body.style.overflow = ""
    this.reset()
  }

  async submit(event) {
    event.preventDefault()
    const form = event.target
    this.errorTarget.hidden = true

    try {
      const response = await fetch(form.action, {
        method: "POST",
        headers: this.headers,
        body: new FormData(form)
      })
      if (response.ok) {
        this.showSuccess()
      } else {
        this.errorTarget.hidden = false
      }
    } catch {
      this.errorTarget.hidden = false
    } finally {
      this.resetTurnstile(form)
    }
  }

  // The submit spent this form's Turnstile token, whether or not it succeeded, and
  // the modal never navigates — so without a reset the next submit replays a dead
  // token and is rejected. The widget owns the how (see turnstile_controller.js);
  // this only announces that a submit finished.
  //
  // Dispatched onto the widget itself rather than the form: the widget is nested
  // inside the form, so a bubbling event from the form would travel away from it.
  // No widget is present when Turnstile is disabled (the test env), hence the guard.
  resetTurnstile(form) {
    const widget = form.querySelector(`[data-controller~="${TURNSTILE_CONTROLLER}"]`)
    widget?.dispatchEvent(new CustomEvent("turnstile:reset"))
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget || event.target.dataset.feedbackBackdrop !== undefined) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && !this.modalTarget.hidden) {
      this.close()
    }
  }

  showSuccess() {
    this.formPanelTarget.hidden = true
    this.successPanelTarget.hidden = false
  }

  // Return the modal to its blank form state, ready for the next open. The
  // input event keeps the markdown live-preview in sync with the cleared field
  // (the modal is only toggled hidden, never reconnected, so the preview
  // controller won't otherwise refresh).
  reset() {
    this.fieldTarget.value = ""
    this.fieldTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.errorTarget.hidden = true
    this.formPanelTarget.hidden = false
    this.successPanelTarget.hidden = true
  }

  // Include the CSRF header only when the token meta is present. It is rendered
  // in every real (non-test) environment; test env disables forgery protection
  // and omits the meta, so guarding avoids a null dereference there.
  get headers() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    return token ? { "X-CSRF-Token": token } : {}
  }
}
