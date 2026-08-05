import { Controller } from "@hotwired/stimulus"

// The feedback modal, opened from the nav drawer. On open it captures the URL
// of the page the user is on into a hidden field. Submitting posts via fetch so
// the page never navigates — on success the modal swaps to an in-place "thanks"
// panel; the user stays exactly where they were. Cancel/backdrop/Escape dismiss.
export default class extends Controller {
  static targets = ["modal", "field", "url", "error", "formPanel", "successPanel"]

  open() {
    this.reset()
    this.urlTarget.value = window.location.href
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
    }
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
