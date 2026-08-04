import { Controller } from "@hotwired/stimulus"

// Confirmation modal for deleting a game. The submit button stays disabled
// until the GM types the game's exact name, guarding against an accidental
// destructive action.
export default class extends Controller {
  static targets = ["modal", "input", "submit"]
  static values = { name: String }

  open() {
    this.modalTarget.hidden = false
    document.body.style.overflow = "hidden"
    this.inputTarget.focus()
  }

  close() {
    this.modalTarget.hidden = true
    document.body.style.overflow = ""
    this.inputTarget.value = ""
    this.validate()
  }

  validate() {
    this.submitTarget.disabled = this.inputTarget.value.trim() !== this.nameValue
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget || event.target.dataset.gameDeleteBackdrop !== undefined) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && !this.modalTarget.hidden) {
      this.close()
    }
  }
}
