import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: String }

  confirm(event) {
    event.preventDefault()
    event.stopImmediatePropagation()

    if (!confirm(this.messageValue)) return

    this.element.submit()
  }
}
