import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    this.element.querySelectorAll('[data-unread="true"]').forEach(post => {
      post.classList.add("post-unread-aura")

      const url = post.dataset.markReadUrl
      if (!url) return

      setTimeout(() => {
        fetch(url, {
          method: "POST",
          headers: {
            "X-CSRF-Token": csrfToken,
            "Accept": "application/json"
          }
        })
      }, 4000)
    })
  }
}
