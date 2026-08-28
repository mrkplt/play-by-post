import { Controller } from "@hotwired/stimulus"

// Reveals the "Edit" link on a post the signed-in viewer authored, client-side,
// so a live-streamed post (rendered viewer-neutral by PostBroadcast, with no
// server-rendered Edit link) still offers the author their edit affordance —
// without a per-viewer server render. On a full page load the link is already
// server-rendered and the slot is non-empty, so this leaves it alone.
//
// The window is advisory only: the edit route is server-enforced (require_editable!),
// so this is pure discoverability. Once the window passes we hide the link again.
export default class extends Controller {
  static targets = ["slot"]
  static values = { authorId: Number, editableUntil: String, editUrl: String }

  connect() {
    this._render()
  }

  _render() {
    if (!this.hasSlotTarget) return
    // Never override a server-rendered link, and only ever offer the viewer's
    // own posts within the (advisory) edit window.
    if (this.slotTarget.children.length > 0) return
    if (this.authorIdValue !== this._currentUserId()) return
    if (!this._withinWindow()) {
      this.slotTarget.replaceChildren()
      return
    }

    const link = document.createElement("a")
    link.href = this.editUrlValue
    link.className = "text-accent font-semibold"
    link.textContent = "Edit"
    this.slotTarget.replaceChildren(link)
  }

  _withinWindow() {
    if (!this.hasEditableUntilValue || this.editableUntilValue === "") return true
    return new Date() < new Date(this.editableUntilValue)
  }

  _currentUserId() {
    const meta = document.querySelector("meta[name='current-user-id']")
    return meta ? Number(meta.content) : null
  }
}
