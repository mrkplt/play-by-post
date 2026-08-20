# typed: strict

module AiKeypairs
  # Decrypts the browser's hybrid-encrypted BYOK key envelope back to the
  # plaintext OpenRouter key, using a user's AiPrivateKey. Keypair generation
  # lives separately in KeypairGenerator; the envelope shape is Blob.
  #
  # == Envelope / blob format (browser encrypts, this class decrypts)
  #
  # The browser holds the plaintext BYOK key only in memory and never sends it
  # unencrypted. It fetches AiKeypair#public_key (PEM, RSA-2048) and, using
  # WebCrypto SubtleCrypto, builds a hybrid AES-GCM envelope:
  #
  #   1. Generate a random AES-256 key (SubtleCrypto.generateKey, "AES-GCM", 256).
  #   2. Generate a random 12-byte IV (crypto.getRandomValues(new Uint8Array(12))).
  #   3. AES-GCM-encrypt the UTF-8 plaintext BYOK key with that key + IV
  #      (SubtleCrypto.encrypt). WebCrypto appends the 16-byte (128-bit) GCM
  #      authentication tag to the END of the returned ciphertext buffer —
  #      this class expects that same layout, not a separately-carried tag.
  #   4. RSA-OAEP-256-wrap the raw AES key bytes with the imported public key:
  #      import the PEM public key with
  #      `{ name: "RSA-OAEP", hash: "SHA-256" }` (this is what makes it
  #      "OAEP-256" — the hash used inside OAEP, and per the WebCrypto/RFC
  #      8017 spec also the MGF1 hash), then
  #      `SubtleCrypto.encrypt({ name: "RSA-OAEP" }, publicKey, aesKeyBytes)`.
  #      Encrypt the raw AES key bytes directly — do NOT use SubtleCrypto's
  #      wrapKey, so the output is a plain ciphertext buffer matching what
  #      #decrypt expects.
  #   5. Base64-encode (standard alphabet, WITH padding) each of:
  #        wrapped_key: the RSA-OAEP output from step 4
  #        iv:          the 12-byte IV from step 2
  #        ciphertext:  the AES-GCM output from step 3 (ciphertext + tag)
  #      into a JSON object with exactly those three keys (see Blob).
  #
  # This class is the only place that ever holds the decrypted plaintext BYOK
  # key; callers are expected to use it and discard it, never persist it.
  class CryptoService
    extend T::Sig

    # RSA-OAEP with SHA-256 as both the OAEP hash and the MGF1 hash — matches
    # WebCrypto's `{ name: "RSA-OAEP", hash: "SHA-256" }`. OpenSSL::PKey's
    # legacy #public_encrypt/#private_decrypt only supports SHA-1 OAEP, so
    # this uses the modern #encrypt/#decrypt(data, options) API instead.
    OAEP_ENCRYPT_OPTIONS = T.let(
      { rsa_padding_mode: "oaep", rsa_oaep_md: "SHA256", rsa_mgf1_md: "SHA256" }.freeze,
      T::Hash[Symbol, String]
    )
    AES_GCM_CIPHER = "aes-256-gcm"
    AES_GCM_TAG_BYTES = 16

    sig { params(private_key_pem: String).void }
    def initialize(private_key_pem)
      @rsa_key = T.let(OpenSSL::PKey::RSA.new(private_key_pem), OpenSSL::PKey::RSA)
    end

    # Decrypts a browser-produced envelope (see the class comment for the
    # exact format) back to the plaintext BYOK key. Raises DecryptionError on
    # any malformed input or failed authentication (tampered ciphertext,
    # wrong key, wrong IV) — GCM authentication failure and base64/format
    # errors are collapsed into one caller-facing error so a plaintext-key
    # decryption failure can't be distinguished by exception type
    # (side-channel hardening for a security-sensitive path).
    sig { params(blob: Blob).returns(String) }
    def decrypt(blob)
      aes_key = unwrap_aes_key(blob.wrapped_key)
      decrypt_payload(aes_key: aes_key, iv: decode64(blob.iv), ciphertext_and_tag: decode64(blob.ciphertext))
    rescue ArgumentError, TypeError, OpenSSL::PKey::PKeyError, OpenSSL::Cipher::CipherError => e
      raise DecryptionError, "failed to decrypt BYOK key blob: #{e.message}"
    end

    private

    sig { params(wrapped_key_b64: String).returns(String) }
    def unwrap_aes_key(wrapped_key_b64)
      # T.unsafe: Sorbet's bundled openssl RBI only knows the legacy
      # #private_decrypt(data, padding) signature, which cannot select
      # SHA-256 for OAEP (it hardcodes SHA-1). #decrypt(data, options) is a
      # real, documented OpenSSL::PKey::RSA method (verified against the
      # installed openssl gem) with no RBI-covered equivalent for OAEP-256.
      T.unsafe(@rsa_key).decrypt(decode64(wrapped_key_b64), OAEP_ENCRYPT_OPTIONS)
    end

    sig { params(aes_key: String, iv: String, ciphertext_and_tag: String).returns(String) }
    def decrypt_payload(aes_key:, iv:, ciphertext_and_tag:)
      raise ArgumentError, "ciphertext too short to contain a GCM tag" if ciphertext_and_tag.bytesize < AES_GCM_TAG_BYTES

      ciphertext = T.must(ciphertext_and_tag[0...-AES_GCM_TAG_BYTES])
      tag = T.must(ciphertext_and_tag[-AES_GCM_TAG_BYTES..])

      cipher = OpenSSL::Cipher.new(AES_GCM_CIPHER)
      cipher.decrypt
      cipher.key = aes_key
      cipher.iv = iv
      cipher.auth_tag = tag
      cipher.auth_data = ""

      cipher.update(ciphertext) + cipher.final
    end

    sig { params(value: String).returns(String) }
    def decode64(value)
      Base64.strict_decode64(value)
    end
  end
end
