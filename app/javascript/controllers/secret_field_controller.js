import { Controller } from "@hotwired/stimulus"

// Reveal/hide and copy for Ui::SecretFieldComponent. The real value lives in a
// Stimulus value (not the visible input), so the masked display never carries
// it until the user reveals. Copy always writes the real value.
export default class extends Controller {
  static targets = ["display", "toggle"]
  static values = { value: String }

  connect() {
    this.revealed = false
    this.mask = this.displayTarget.value
  }

  toggle() {
    this.revealed = !this.revealed
    this.displayTarget.value = this.revealed ? this.valueValue : this.mask
    this.toggleTarget.textContent = this.revealed ? "Hide" : "Show"
    this.toggleTarget.setAttribute("aria-label", this.revealed ? "Hide value" : "Show value")
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.valueValue)
    } catch (_e) {
      // Clipboard API unavailable (insecure context / permissions) — no-op.
    }
  }
}
