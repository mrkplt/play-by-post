import { Controller } from "@hotwired/stimulus"

// Polls a Turbo Frame until the backend has produced its content, then stops.
//
// Attached directly to the Turbo Frame (see Shared::AsyncPendingComponent). The
// frame ships WITHOUT a `src` so Turbo does not eager-load it (a self-
// referential `src` set in HTML no-ops on load and empties the frame); this
// controller owns fetching instead. It sets the frame's `src` on an interval —
// each assignment re-fetches the poll path via Turbo — until the item exists,
// when the server returns the READY frame with no controller. Turbo swaps that
// in, Stimulus disconnects this instance, and `disconnect` stops the timer.
// Presence-only: no per-user state; every viewer of a pending page polls.
export default class extends Controller {
  static values = { interval: Number, src: String }

  connect() {
    const interval = this.intervalValue > 0 ? this.intervalValue : 3000
    this.poll()
    this.timer = setInterval(() => this.poll(), interval)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  // Force a fresh fetch of the poll path. Clearing src first means re-assigning
  // the same value still triggers a load (Turbo ignores a no-op reassignment).
  poll() {
    this.element.removeAttribute("src")
    this.element.src = this.srcValue
  }
}
