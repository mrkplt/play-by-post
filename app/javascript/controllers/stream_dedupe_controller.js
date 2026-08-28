import { Controller } from "@hotwired/stimulus"

// Cancels the redundant second delivery of a created post. The submitter's tab
// renders a new post twice: once from the direct turbo_stream response and once
// from the PostBroadcast every subscriber receives — byte-identical appends
// sharing the post's dom_id. Turbo handles an append whose child id already
// exists by removing the existing element and appending the new one, which
// detaches the live node mid-interaction (destroying the client-revealed Edit
// link the author may be about to click). Whichever copy arrives second changes
// nothing, so cancel its append instead of letting it clobber the node. An
// append of a post this tab has not rendered (every other viewer's case) passes
// through untouched; edits broadcast as replace and are unaffected.
export default class extends Controller {
  connect() {
    this._cancelDuplicateAppend = (event) => this._cancelIfDuplicate(event)
    document.addEventListener("turbo:before-stream-render", this._cancelDuplicateAppend)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this._cancelDuplicateAppend)
  }

  _cancelIfDuplicate(event) {
    const stream = event.target
    if (stream.action !== "append" || stream.target !== this.element.id) return

    const children = Array.from(stream.templateElement.content.children)
    if (children.length === 0) return
    if (children.every((child) => child.id && document.getElementById(child.id))) event.preventDefault()
  }
}
