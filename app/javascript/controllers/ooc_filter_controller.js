import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    const hide = event.target.checked
    this.element.querySelectorAll("[data-ooc='true']").forEach(el => {
      el.style.display = hide ? "none" : ""
    })
  }
}
