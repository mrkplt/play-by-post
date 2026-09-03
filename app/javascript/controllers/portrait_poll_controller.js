import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

// Polls the portrait generation endpoint on an interval while a generation is
// in flight, applying the Turbo Stream it returns. The stream replaces this
// control and the portrait library, so a finished portrait appears in place.
//
// Self-terminating, like frame-poll: while the generation is still pending the
// server re-renders the spinner (a fresh instance of this controller schedules
// the next poll); once it settles the server renders the form with no
// controller, so polling stops naturally. No websocket, no reload.
export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 1500 }
  }

  connect() {
    this.timer = setTimeout(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  async poll() {
    const response = await fetch(this.urlValue, {
      headers: { "Accept": "text/vnd.turbo-stream.html" }
    })
    if (response.ok) {
      Turbo.renderStreamMessage(await response.text())
    }
  }
}
