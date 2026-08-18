import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// Drives the upload-and-crop modal (Shared::ImageCropperComponent): pick a
// file, crop it to a square with Cropper.js, and POST the cropped blob to the
// library's upload URL as multipart form data. Crop-on-upload only — the stored
// image is already square, so no server-side cropping is needed.
//
// No <dialog>/alert/confirm: the modal is a plain toggled element, so it never
// blocks the browser event loop.
export default class extends Controller {
  static targets = ["modal", "fileInput", "cropArea", "image", "saveButton", "error"]
  static values = { uploadUrl: String }

  connect() {
    this.cropper = null
  }

  disconnect() {
    this.destroyCropper()
  }

  open() {
    this.reset()
    this.modalTarget.classList.remove("hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.reset()
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) this.close()
  }

  reset() {
    this.destroyCropper()
    this.fileInputTarget.value = ""
    this.cropAreaTarget.classList.add("hidden")
    this.saveButtonTarget.disabled = true
    this.hideError()
  }

  fileChosen() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (event) => this.startCropper(event.target.result)
    reader.readAsDataURL(file)
  }

  startCropper(dataUrl) {
    this.destroyCropper()
    this.imageTarget.src = dataUrl
    this.cropAreaTarget.classList.remove("hidden")
    this.cropper = new Cropper(this.imageTarget, {
      aspectRatio: 1,
      viewMode: 1,
      dragMode: "move",
      autoCropArea: 1,
      background: false,
      responsive: true
    })
    this.saveButtonTarget.disabled = false
  }

  zoomIn() {
    if (this.cropper) this.cropper.zoom(0.1)
  }

  zoomOut() {
    if (this.cropper) this.cropper.zoom(-0.1)
  }

  rotateLeft() {
    if (this.cropper) this.cropper.rotate(-90)
  }

  rotateRight() {
    if (this.cropper) this.cropper.rotate(90)
  }

  save() {
    if (!this.cropper) return

    this.saveButtonTarget.disabled = true
    const canvas = this.cropper.getCroppedCanvas({ width: 512, height: 512 })
    canvas.toBlob((blob) => this.upload(blob), "image/jpeg", 0.9)
  }

  async upload(blob) {
    const body = new FormData()
    body.append("image[file]", blob, "portrait.jpg")

    try {
      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken() },
        body
      })

      if (response.redirected) {
        window.location.href = response.url
      } else if (response.ok) {
        window.location.reload()
      } else {
        this.showError("Upload failed. Please try again.")
      }
    } catch (error) {
      this.showError("Upload failed. Please try again.")
    }
  }

  csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
    this.saveButtonTarget.disabled = false
  }

  hideError() {
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }
}
