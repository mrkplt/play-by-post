import { Controller } from "@hotwired/stimulus"

// Submits the notebook lane picker when a GM chooses a status.
//
// The blur before the submit is the point. `change` fires while the select
// still holds focus and, on Safari and Firefox, while its dropdown is still
// painted. The move response replaces the whole lane — including this select —
// so submitting straight from `change` destroys the element the browser is
// drawing a popup for, and the popup is left orphaned over the board with no
// element to dismiss it. Blurring first closes the popup while the select is
// still there to receive it.
export default class extends Controller {
  submit(event) {
    event.target.blur()
    this.element.requestSubmit()
  }
}
