import { Controller } from "@hotwired/stimulus"

// Reloads the enclosing Turbo Frame on an interval until the server stops
// rendering this controller into it — a deterministic "wait for the backend"
// primitive with no websocket dependency. Each reload replaces the frame's
// content; while the awaited state isn't ready the server renders this
// controller again (a fresh instance schedules the next poll), and once it is
// ready the resolved markup carries no controller, so polling stops naturally.
export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 1000 }
  }

  connect() {
    this.timer = setTimeout(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  poll() {
    const frame = this.element.closest("turbo-frame")
    if (!frame) return

    if (frame.getAttribute("src")) {
      frame.reload()
    } else {
      frame.src = this.urlValue
    }
  }
}
