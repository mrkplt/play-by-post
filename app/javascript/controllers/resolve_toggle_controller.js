import { Controller } from "@hotwired/stimulus"

// Toggles the End Scene resolve form's visibility. Replaces the old
// onclick="document.getElementById('resolve-form')..." coupling: the button
// and the form are both inside this controller's element, addressed by
// Stimulus target rather than a hardcoded DOM id.
export default class extends Controller {
  static targets = ["form"]

  toggle() {
    this.formTarget.hidden = !this.formTarget.hidden
  }
}
