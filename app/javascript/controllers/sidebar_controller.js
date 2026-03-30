import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop"]

  open() {
    this.sidebarTarget.dataset.open = ""
    this.backdropTarget.hidden = false
  }

  close() {
    delete this.sidebarTarget.dataset.open
    this.backdropTarget.hidden = true
  }

  closeOnOutside(event) {
    if (window.innerWidth >= 768) return
    if (!this.sidebarTarget.contains(event.target)) {
      this.close()
    }
  }
}
