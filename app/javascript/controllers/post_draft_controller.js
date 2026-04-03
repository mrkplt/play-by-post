import { Controller } from "@hotwired/stimulus"

const AUTOSAVE_DELAY_MS = 2000

export default class extends Controller {
  static targets = ["content", "saveAsDraftToggle", "status"]
  static values = { saveUrl: String }

  connect() {
    this._timer = null
  }

  disconnect() {
    clearTimeout(this._timer)
  }

  scheduleSave() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this._saveDraft(), AUTOSAVE_DELAY_MS)
  }

  toggleSaveAsDraft() {
    const form = this.element
    const submit = form.querySelector('[type="submit"]')
    if (!submit) return

    if (this.saveAsDraftToggleTarget.checked) {
      submit.value = "Save Draft"
      form.dataset.saveAsDraft = "true"
      form.addEventListener("submit", this._interceptSubmit, { once: false })
    } else {
      submit.value = "Post"
      delete form.dataset.saveAsDraft
      form.removeEventListener("submit", this._interceptSubmit)
    }
  }

  _interceptSubmit = (event) => {
    if (!this.element.dataset.saveAsDraft) return
    event.preventDefault()
    this._saveDraft().then(() => {
      this._showStatus("Draft saved.")
    })
  }

  async _saveDraft() {
    const content = this.contentTarget.value
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(this.saveUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ post: { content } })
      })

      if (response.ok) {
        this._showStatus("Draft saved.")
      }
    } catch {
      // silent — autosave failures should not interrupt the user
    }
  }

  _showStatus(message) {
    if (!this.hasStatusTarget) return
    const el = this.statusTarget
    el.textContent = message
    el.classList.remove("hidden")
    clearTimeout(this._statusTimer)
    this._statusTimer = setTimeout(() => el.classList.add("hidden"), 3000)
  }
}
