import { Controller } from "@hotwired/stimulus"

// Glows unread posts and auto-marks-them-read after a dwell. Handles both the
// posts present at page load and posts that stream in live (PostBroadcast) after
// connect — a live post arrives with data-unread="true", and this observer
// glows/marks it the same as a cold-load unread post.
//
// A viewer never glows their OWN post: a broadcast render is viewer-neutral and
// cannot know who is looking, so it always marks a new post unread; this client
// removes the glow (and skips mark-read) when the post's author is the signed-in
// viewer, using the same current-user-id meta the edit-affordance controller reads.
export default class extends Controller {
  connect() {
    this.element.querySelectorAll('[data-unread="true"]').forEach(post => this._process(post))

    // Streamed-in posts are appended after connect; glow/mark them as they land.
    this._observer = new MutationObserver(records => {
      records.forEach(record => {
        record.addedNodes.forEach(node => {
          if (node.nodeType !== Node.ELEMENT_NODE) return
          if (node.matches?.('[data-unread="true"]')) this._process(node)
          node.querySelectorAll?.('[data-unread="true"]').forEach(post => this._process(post))
        })
      })
    })
    this._observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    if (this._observer) this._observer.disconnect()
  }

  _process(post) {
    // Never glow or mark-read the viewer's own post.
    if (this._isOwnPost(post)) {
      post.classList.remove("ui-glow")
      return
    }
    if (post.dataset.auraProcessed) return
    post.dataset.auraProcessed = "true"

    post.classList.add("ui-glow")

    const url = post.dataset.markReadUrl
    if (!url) return
    setTimeout(() => {
      fetch(url, {
        method: "POST",
        headers: { "X-CSRF-Token": this._csrfToken(), "Accept": "application/json" }
      })
    }, 4000)
  }

  _isOwnPost(post) {
    const currentUserId = this._currentUserId()
    if (currentUserId === null) return false
    const authorId = Number(post.dataset.postEditAffordanceAuthorIdValue)
    return authorId === currentUserId
  }

  _currentUserId() {
    const meta = document.querySelector("meta[name='current-user-id']")
    return meta ? Number(meta.content) : null
  }

  _csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
