import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

// Drives Shared::ImageLibraryComponent's selection: click a thumbnail and the
// large preview at the top updates immediately (client-side, no server
// round-trip) — a Save button then persists the pending selection to the
// image's existing set-current URL (the same PATCH the old "Use" button hit)
// and applies the server's Turbo Stream response (library swap + toast) in
// place. No window.location.reload().
//
// Selection state is held entirely as data attributes on the target elements
// (never a bare instance field) so a Turbo Stream replace of the library
// section — which tears down and reconnects this controller — cannot leave
// pending JS state pointing at now-detached DOM nodes.
export default class extends Controller {
  static targets = ["current", "thumb", "save"]

  // A thumbnail was clicked: preview it large immediately and mark it pending
  // (ring moves to it), without touching the server yet.
  select(event) {
    const thumb = event.currentTarget
    const displayUrl = thumb.dataset.imageSelectDisplayUrlParam
    if (!displayUrl) return

    if (this.hasCurrentTarget) this.currentTarget.src = displayUrl
    this._markPending(thumb)
    this._updateSaveState()
  }

  async save() {
    const pending = this._pendingThumb()
    if (!pending || this.saveTarget.disabled) return

    const setCurrentUrl = pending.dataset.imageSelectSetCurrentUrlParam
    if (!setCurrentUrl) return

    this.saveTarget.disabled = true

    try {
      const response = await fetch(setCurrentUrl, {
        method: "PATCH",
        headers: { "X-CSRF-Token": this._csrfToken(), "Accept": "text/vnd.turbo-stream.html" }
      })

      if (response.ok) {
        // The controller answers with a Turbo Stream that swaps the library
        // section (and a toast) in place — apply it, no full-page reload.
        Turbo.renderStreamMessage(await response.text())
      } else {
        this.saveTarget.disabled = false
      }
    } catch (error) {
      this.saveTarget.disabled = false
    }
  }

  // Move the "selected" ring to the clicked thumbnail and off every other one,
  // marking exactly one thumbnail pending — reusing the same two classes the
  // server applies on a cold load so client and server selection never look
  // different.
  _markPending(selected) {
    const CURRENT_RING = [ "border-accent", "ring-2", "ring-accent" ]
    const IDLE_BORDER = [ "border-card-border" ]

    this.thumbTargets.forEach(thumb => {
      const isSelected = thumb === selected
      thumb.classList.remove(...CURRENT_RING, ...IDLE_BORDER)
      thumb.classList.add(...(isSelected ? CURRENT_RING : IDLE_BORDER))
      thumb.dataset.imageSelectPending = isSelected ? "true" : "false"
    })
  }

  _pendingThumb() {
    return this.thumbTargets.find(thumb => thumb.dataset.imageSelectPending === "true")
  }

  // Save is only meaningful once the pending selection differs from the image
  // already current server-side — clicking the already-current thumbnail (or
  // nothing at all) leaves it disabled.
  _updateSaveState() {
    if (!this.hasSaveTarget) return

    const pending = this._pendingThumb()
    const alreadyCurrent = pending && pending.dataset.imageSelectCurrentParam === "true"
    this.saveTarget.disabled = !pending || alreadyCurrent
  }

  _csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }
}
