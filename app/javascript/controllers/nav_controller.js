import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    const hasItems = this.menuTarget.querySelectorAll("a, button").length > 0
    this.toggleTarget.hidden = !hasItems
  }

  toggle() {
    const isHidden = this.menuTarget.hidden
    this.menuTarget.hidden = !isHidden
    this.toggleTarget.setAttribute("aria-expanded", isHidden ? "true" : "false")
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.hidden = true
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }
}
