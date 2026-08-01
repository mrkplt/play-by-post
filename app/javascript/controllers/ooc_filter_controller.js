import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "switch"]
  static values = { hideOoc: Boolean, toggleUrl: String }

  connect() {
    this.hiding = this.hideOocValue
    this._applyFilter()
    this._updateIndicator()
    this._updateSwitch()
  }

  toggle() {
    this.hiding = !this.hiding
    this._applyFilter()
    this._updateIndicator()
    this._updateSwitch()
    this._persist()
  }

  // Reflect on/off state on the Ui::ToggleSwitch markup: move the thumb and
  // recolor the track.
  _updateSwitch() {
    if (!this.hasSwitchTarget) return
    const track = this.switchTarget.querySelector("[role='switch']")
    const thumb = track && track.firstElementChild
    if (!track || !thumb) return
    track.setAttribute("aria-checked", String(this.hiding))
    track.classList.toggle("bg-accent", this.hiding)
    track.classList.toggle("bg-[#3a3c42]", !this.hiding)
    thumb.classList.toggle("right-0.5", this.hiding)
    thumb.classList.toggle("left-0.5", !this.hiding)
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
