import { Controller } from "@hotwired/stimulus"

// The feedback modal, opened from the nav drawer. When opened it captures the
// URL of the page the user was on into a hidden field, so the saved feedback
// record notes where the feedback was about. Cancel/backdrop/Escape dismiss it.
export default class extends Controller {
  static targets = ["modal", "field", "url"]

  open() {
    this.urlTarget.value = window.location.href
    this.modalTarget.hidden = false
    document.body.style.overflow = "hidden"
    this.fieldTarget.focus()
  }

  close() {
    this.modalTarget.hidden = true
    document.body.style.overflow = ""
    this.fieldTarget.value = ""
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
}
