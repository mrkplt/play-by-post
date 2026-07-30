import { Controller } from "@hotwired/stimulus"

// Warns immediately when a selected file exceeds the allowed size, before the
// upload is attempted. Server-side validation remains the source of truth.
export default class extends Controller {
  static targets = ["input", "warning", "submit"]
  static values = { maxBytes: Number }

  connect() {
    this.check()
  }

  check() {
    const file = this.inputTarget.files && this.inputTarget.files[0]
    if (!file || file.size <= this.maxBytesValue) {
      this.clearWarning()
      return
    }
    this.showWarning(file.size)
  }

  showWarning(size) {
    const limitMb = Math.round(this.maxBytesValue / (1024 * 1024))
    const fileMb = (size / (1024 * 1024)).toFixed(1)
    this.warningTarget.textContent =
      `This file is ${fileMb} MB, which is over the ${limitMb} MB limit. Please choose a smaller file.`
    this.warningTarget.classList.remove("hidden")
    if (this.hasSubmitTarget) this.submitTarget.disabled = true
  }

  clearWarning() {
    this.warningTarget.textContent = ""
    this.warningTarget.classList.add("hidden")
    if (this.hasSubmitTarget) this.submitTarget.disabled = false
  }
}
