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

    // A previous submit spent the token and triggered a reset, and the
    // replacement arrives asynchronously — so wait for it rather than posting an
    // empty token the server would reject. Resolves immediately on the first
    // submit, and whenever Turnstile is absent.
    await this.turnstile(form)?.ready()

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
      // The submit spent the token whether or not it succeeded, so start the
      // replacement now; the next submit awaits it above.
      this.turnstile(form)?.reset()
    }
  }

  // The widget's own controller, which owns the reset/ready lifecycle so this one
  // never touches the Turnstile API. Null when Turnstile is disabled (the test
  // env renders no widget) or before Stimulus has connected the controller.
  turnstile(form) {
    const element = form.querySelector(`[data-controller~="${TURNSTILE_CONTROLLER}"]`)
    if (!element) return null

    return this.application.getControllerForElementAndIdentifier(element, TURNSTILE_CONTROLLER)
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
