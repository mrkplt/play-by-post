import { Controller } from "@hotwired/stimulus"

// Auto-dismiss for a success toast in Ui::ToastComponent: hold solid, then
// fade out and remove the node. Only self-dismissing variants get this
// controller attached — an error toast has no timer and waits for its button.
//
// Timings mirror the --toast-hold / --toast-fade theme tokens; the fade
// duration here only has to outlast the CSS transition, which owns the
// actual animation.
const HOLD_MS = 2000
const FADE_MS = 3000

export default class extends Controller {
  static values = { autoDismiss: Boolean }

  connect() {
    if (!this.autoDismissValue) return

    this.holdTimer = setTimeout(() => this.dismiss(), HOLD_MS)
  }

  // Clearing on disconnect matters because Turbo swaps the body out from
  // under a toast mid-fade on the next navigation; a live timer would then
  // call remove() against a detached node.
  disconnect() {
    clearTimeout(this.holdTimer)
    clearTimeout(this.fadeTimer)
  }

  dismiss() {
    clearTimeout(this.holdTimer)
    this.element.classList.add("toast--leaving")
    this.fadeTimer = setTimeout(() => this.element.remove(), FADE_MS)
  }
}
