import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

marked.setOptions({ breaks: true, gfm: true })

export default class extends Controller {
  static targets = ["input", "preview"]

  update() {
    if (!this.previewTarget.hidden) {
      this.previewTarget.innerHTML = marked.parse(this.inputTarget.value || "")
    }
  }

  togglePreview() {
    const shown = !this.previewTarget.hidden
    this.previewTarget.hidden = shown
    if (!shown) {
      this.previewTarget.innerHTML = marked.parse(this.inputTarget.value || "")
    }
  }
}
