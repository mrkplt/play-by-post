import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator"]
  static values = { hideOoc: Boolean, toggleUrl: String }

  connect() {
    this.hiding = this.hideOocValue
    this._applyFilter()
    this._updateIndicator()
  }

  toggle() {
    this.hiding = !this.hiding
    this._applyFilter()
    this._updateIndicator()
    this._persist()
  }

  _applyFilter() {
    this.element.querySelectorAll("[data-ooc='true']").forEach(el => {
      el.hidden = this.hiding
    })
  }

  _updateIndicator() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.textContent = this.hiding ? "✓ On" : "Off"
      this.indicatorTarget.style.color = this.hiding ? "#16a34a" : "#94a3b8"
    }
  }

  _persist() {
    fetch(this.toggleUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    })
  }
}
