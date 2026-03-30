import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop", "toggle"]

  open() {
    this.sidebarTarget.dataset.open = ""
    this.backdropTarget.hidden = false
    this.toggleTarget.hidden = true
  }

  close() {
    delete this.sidebarTarget.dataset.open
    this.backdropTarget.hidden = true
    this.toggleTarget.hidden = false
  }

  closeOnOutside(event) {
    if (window.innerWidth >= 768) return
    if (!this.sidebarTarget.contains(event.target)) {
      this.close()
    }
  }
}
