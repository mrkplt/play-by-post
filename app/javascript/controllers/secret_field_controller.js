import { Controller } from "@hotwired/stimulus"

// Masks a sensitive value (token / feed URL) behind a password field, with a
// toggle to reveal it and a button to copy the real value to the clipboard.
export default class extends Controller {
  static targets = ["input", "toggle", "copy"]

  toggle() {
    const revealed = this.inputTarget.type === "text"
    this.inputTarget.type = revealed ? "password" : "text"
    this.toggleTarget.textContent = revealed ? "Show" : "Hide"
  }

  copy() {
    const value = this.inputTarget.value
    const done = () => { this.copyTarget.textContent = "Copied" }

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(value).then(done)
    } else {
      this.inputTarget.type = "text"
      this.inputTarget.select()
      document.execCommand("copy")
      done()
    }
  }
}
