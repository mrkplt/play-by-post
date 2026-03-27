import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  open(event) {
    const card = event.currentTarget
    this.modalTarget.querySelector("[data-lightbox-image]").innerHTML = card.dataset.lightboxHtml || ""
    this.modalTarget.querySelector("[data-lightbox-title]").textContent = card.dataset.lightboxFilename || ""

    const downloadLink = this.modalTarget.querySelector("[data-lightbox-download]")
    downloadLink.href = card.dataset.lightboxDownload || "#"

    const deleteBtn = this.modalTarget.querySelector("[data-lightbox-delete-btn]")
    if (deleteBtn) {
      const deleteUrl = card.dataset.lightboxDelete
      if (deleteUrl) {
        deleteBtn.hidden = false
        deleteBtn.dataset.deleteUrl = deleteUrl
      } else {
        deleteBtn.hidden = true
      }
    }

    this.modalTarget.hidden = false
    document.body.style.overflow = "hidden"
  }

  close() {
    this.modalTarget.hidden = true
    document.body.style.overflow = ""
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget || event.target.dataset.lightboxBackdrop !== undefined) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && !this.modalTarget.hidden) {
      this.close()
    }
  }

  confirmDelete(event) {
    const deleteUrl = event.target.dataset.deleteUrl
    if (!deleteUrl) return
    if (!confirm("Delete this file?")) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    fetch(deleteUrl, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/html"
      },
      redirect: "follow"
    }).then(() => {
      window.location.reload()
    })
  }
}
