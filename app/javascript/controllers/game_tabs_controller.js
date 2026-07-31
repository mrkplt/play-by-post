import { Controller } from "@hotwired/stimulus"

// Client-side pill tabs for the game view: shows one panel at a time and
// gold-fills the active pill. Panels and tab buttons pair up by data-tab /
// data-panel. Deep-linkable via the URL hash (#roster, #files).
export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "idle"]

  connect() {
    const fromHash = window.location.hash.replace("#", "")
    const initial = this.panelTargets.some((p) => p.dataset.panel === fromHash)
      ? fromHash
      : this._current()
    this._show(initial)
  }

  switch(event) {
    const name = event.currentTarget.dataset.tab
    this._show(name)
    history.replaceState(null, "", `#${name}`)
  }

  _current() {
    const active = this.tabTargets.find((t) => t.getAttribute("aria-current") === "page")
    return active ? active.dataset.tab : (this.panelTargets[0] && this.panelTargets[0].dataset.panel)
  }

  _show(name) {
    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.panel !== name
    })
    this.tabTargets.forEach((tab) => {
      const on = tab.dataset.tab === name
      tab.setAttribute("aria-current", on ? "page" : "false")
      tab.classList.toggle("bg-accent", on)
      tab.classList.toggle("text-accent-ink", on)
      tab.classList.toggle("bg-pill-idle", !on)
      tab.classList.toggle("text-sidebar-text", !on)
    })
  }
}
