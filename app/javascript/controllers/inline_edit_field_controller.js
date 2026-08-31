import { Controller } from "@hotwired/stimulus"

// Toggles a single-line field (Ui::ProfileDisplayNameFieldComponent) between
// its view row (label + Edit) and its edit row (text input + Save/Cancel),
// client-side — no navigation to a separate edit page. Save is a normal form
// submit; the controller answers with a Turbo Stream that replaces this whole
// element, so a successful save (or a validation failure that re-opens edit
// mode with an error) both land through the server response, not this
// controller. This controller only owns the local, no-request toggle: opening
// the field and cancelling out of it.
export default class extends Controller {
  static targets = ["view", "edit", "input"]

  connect() {
    this.originalValue = this.inputTarget.value
  }

  edit() {
    this.viewTarget.hidden = true
    this.editTarget.hidden = false
    this.inputTarget.focus()
  }

  cancel() {
    this.inputTarget.value = this.originalValue
    this.editTarget.hidden = true
    this.viewTarget.hidden = false
  }
}
