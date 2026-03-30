import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

marked.setOptions({ breaks: true, gfm: true })

export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    this.update()
  }

  update() {
    this.previewTarget.innerHTML = marked.parse(this.inputTarget.value || "")
  }
}
