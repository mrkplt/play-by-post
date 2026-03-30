import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    this._hasItems = this.menuTarget.querySelectorAll("a, button").length > 0
    this._resizeHandler = this.updateVisibility.bind(this)
    this.updateVisibility()
    window.addEventListener("resize", this._resizeHandler)
  }

  disconnect() {
    window.removeEventListener("resize", this._resizeHandler)
  }

  updateVisibility() {
    const hasItems = this._hasItems !== undefined ? this._hasItems : this.menuTarget.querySelectorAll("a, button").length > 0
    const isMobile = window.innerWidth < 768
    this.menuTarget.hidden = isMobile
    this.toggleTarget.hidden = !isMobile || !hasItems
  }

  toggle() {
    const isHidden = this.menuTarget.hidden
    this.menuTarget.hidden = !isHidden
    this.toggleTarget.setAttribute("aria-expanded", isHidden ? "true" : "false")
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target) && window.innerWidth < 768) {
      this.menuTarget.hidden = true
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }
}
