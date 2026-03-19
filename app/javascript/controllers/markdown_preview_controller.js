import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  update() {
    if (this.previewTarget.style.display !== "none") {
      this.previewTarget.innerText = this.inputTarget.value
    }
  }

  togglePreview() {
    const shown = this.previewTarget.style.display !== "none"
    this.previewTarget.style.display = shown ? "none" : "block"
    if (!shown) {
      this.previewTarget.innerText = this.inputTarget.value
    }
  }
}
