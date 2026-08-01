import { Controller } from "@hotwired/stimulus"

// Client-side filter for the roster: hides rows whose name/player don't match
// the query. Purely presentational — no server round-trip.
export default class extends Controller {
  static targets = ["query", "row"]

  filter() {
    const q = this.queryTarget.value.trim().toLowerCase()
    this.rowTargets.forEach((row) => {
      const haystack = row.dataset.rosterName || ""
      row.hidden = q.length > 0 && !haystack.includes(q)
    })
  }
}
