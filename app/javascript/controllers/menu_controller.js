import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  toggle() {
    this.dropdownTarget.hidden = !this.dropdownTarget.hidden
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.hidden = true
    }
  }
}
