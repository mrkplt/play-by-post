# typed: false

# Seals a plaintext to a public key exactly as a browser using WebCrypto
# SubtleCrypto is documented to (see AiKeypairs::CryptoService's class comment):
# random AES-256-GCM key + 12-byte IV, ciphertext with the GCM tag appended,
# the AES key wrapped with RSA-OAEP-256. Returns the AiKeypairs::Blob JSON.
#
# Shared by every spec that needs to produce a decryptable envelope
# (CryptoService, StoredKeySource) so the browser-side format lives in one place.
module BrowserSealHelper
  def encrypt_like_a_browser(plaintext, public_key_pem)
    aes_key = OpenSSL::Random.random_bytes(32)
    iv = OpenSSL::Random.random_bytes(12)

    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.encrypt
    cipher.key = aes_key
    cipher.iv = iv
    cipher.auth_data = ""
    ciphertext = cipher.update(plaintext) + cipher.final
    ciphertext_and_tag = ciphertext + cipher.auth_tag

    public_key = OpenSSL::PKey::RSA.new(public_key_pem)
    wrapped_key = public_key.encrypt(
      aes_key, { rsa_padding_mode: "oaep", rsa_oaep_md: "SHA256", rsa_mgf1_md: "SHA256" }
    )

    {
      wrapped_key: Base64.strict_encode64(wrapped_key),
      iv: Base64.strict_encode64(iv),
      ciphertext: Base64.strict_encode64(ciphertext_and_tag)
    }.to_json
  end
end

RSpec.configure do |config|
  config.include BrowserSealHelper
end
