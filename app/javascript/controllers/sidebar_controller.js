import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop", "toggle"]

  open() {
    this.sidebarTarget.dataset.open = ""
    this.backdropTarget.hidden = false
    if (this.hasToggleTarget) this.toggleTarget.hidden = true
  }

  close() {
    delete this.sidebarTarget.dataset.open
    this.backdropTarget.hidden = true
    if (this.hasToggleTarget) this.toggleTarget.hidden = false
  }

  closeOnOutside(event) {
    if (!this.sidebarTarget.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}

