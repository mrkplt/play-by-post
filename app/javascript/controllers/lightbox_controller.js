import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  open(event) {
    if (event.target.closest("[data-lightbox-stop]")) return

    const card = event.currentTarget
    this.modalTarget.querySelector("[data-lightbox-image]").innerHTML = card.dataset.lightboxHtml || ""
    this.modalTarget.querySelector("[data-lightbox-title]").textContent = card.dataset.lightboxFilename || ""

    const downloadLink = this.modalTarget.querySelector("[data-lightbox-download]")
    downloadLink.href = card.dataset.lightboxDownload || "#"

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
}
