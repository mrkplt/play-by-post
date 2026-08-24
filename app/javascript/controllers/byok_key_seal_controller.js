import { Controller } from "@hotwired/stimulus"

// Encrypts a pasted BYOK (bring-your-own OpenRouter key) API key client-side
// with WebCrypto SubtleCrypto, to the keypair's RSA public key, and submits
// only the resulting sealed envelope — the plaintext key never has a `name`
// attribute and is never sent to the server. See
// Crypto::CryptoService's class comment (app/services/crypto/crypto_service.rb)
// for the exact envelope format this must produce; the server-side decrypt
// counterpart is that class.
//
// Envelope: { wrapped_key, iv, ciphertext } — all standard (padded)
// base64:
//   1. Generate a random AES-256-GCM key + 12-byte IV.
//   2. AES-GCM-encrypt the UTF-8 plaintext key (WebCrypto appends the
//      16-byte GCM tag to the ciphertext — no separate tag handling needed).
//   3. RSA-OAEP-256-wrap the raw AES key bytes against the imported public
//      key (encrypt, not wrapKey, so the output is a plain ciphertext buffer
//      matching what CryptoService#decrypt expects).
export default class extends Controller {
  static targets = ["plaintext", "wrappedKey", "iv", "ciphertext", "submit", "error"]
  static values = { publicKey: String }

  // First pass: intercept, seal, then requestSubmit() — which re-fires the
  // submit event. Second pass: the sealed flag lets the event through
  // un-prevented so TURBO performs the submission (element.submit() would be
  // a native full-page POST, bypassing Turbo and bouncing the whole page —
  // the response is a Turbo Stream that must be applied in place).
  async submitForm(event) {
    if (this.sealed) {
      this.sealed = false
      return
    }

    event.preventDefault()
    this.hideError()

    const plaintext = this.plaintextTarget.value
    if (!plaintext) {
      this.showError("Enter an OpenRouter API key.")
      return
    }

    this.submitTarget.disabled = true
    try {
      const envelope = await this.seal(plaintext)
      this.wrappedKeyTarget.value = envelope.wrapped_key
      this.ivTarget.value = envelope.iv
      this.ciphertextTarget.value = envelope.ciphertext
      this.plaintextTarget.value = ""
      this.sealed = true
      this.submitTarget.disabled = false
      // A macrotask, not an immediate call: WebCrypto's microtask chain can
      // finish while the original submit event is still dispatching, and a
      // requestSubmit() issued inside that dispatch is silently dropped (the
      // form's firing-submit flag is still set).
      setTimeout(() => this.element.requestSubmit(), 0)
    } catch (_e) {
      this.showError("Could not encrypt that key in this browser. Try a different browser.")
      this.submitTarget.disabled = false
    }
  }

  async seal(plaintext) {
    const publicKey = await this.importPublicKey()

    const aesKey = await crypto.subtle.generateKey({ name: "AES-GCM", length: 256 }, true, ["encrypt"])
    const iv = crypto.getRandomValues(new Uint8Array(12))

    const ciphertext = await crypto.subtle.encrypt(
      { name: "AES-GCM", iv },
      aesKey,
      new TextEncoder().encode(plaintext)
    )

    const rawAesKey = await crypto.subtle.exportKey("raw", aesKey)
    const wrappedKey = await crypto.subtle.encrypt({ name: "RSA-OAEP" }, publicKey, rawAesKey)

    return {
      wrapped_key: this.toBase64(wrappedKey),
      iv: this.toBase64(iv.buffer),
      ciphertext: this.toBase64(ciphertext)
    }
  }

  async importPublicKey() {
    const der = this.pemToDer(this.publicKeyValue)
    return crypto.subtle.importKey("spki", der, { name: "RSA-OAEP", hash: "SHA-256" }, false, ["encrypt"])
  }

  // Strips the PEM header/footer and newlines, base64-decodes the remaining
  // body into the raw SPKI DER bytes `importKey("spki", ...)` expects.
  pemToDer(pem) {
    const body = pem
      .replace(/-----BEGIN PUBLIC KEY-----/, "")
      .replace(/-----END PUBLIC KEY-----/, "")
      .replace(/\s+/g, "")
    const binary = atob(body)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i)
    }
    return bytes.buffer
  }

  toBase64(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ""
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return btoa(binary)
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
