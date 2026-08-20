require "rails_helper"

RSpec.describe AiKeypairs::CryptoService do
  let(:keypair) { AiKeypairs::KeypairGenerator.call }
  let(:service) { described_class.new(keypair.private_key_pem) }
  let(:plaintext) { "sk-or-v1-fake-openrouter-key-1234567890" }

  # Encrypts the way a browser using WebCrypto SubtleCrypto is documented to
  # (see the class comment on AiKeypairs::CryptoService): random AES-256-GCM
  # key + 12-byte IV, ciphertext with the GCM tag appended, AES key wrapped
  # with RSA-OAEP-256.
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

  describe "#decrypt" do
    it "decrypts a well-formed envelope back to the original plaintext" do
      blob = AiKeypairs::Blob.from_json(encrypt_like_a_browser(plaintext, keypair.public_key_pem))

      expect(service.decrypt(blob)).to eq(plaintext)
    end

    it "round-trips a real WebCrypto SubtleCrypto envelope (spec/fixtures/ai_keypairs)" do
      fixtures_dir = Rails.root.join("spec/fixtures/ai_keypairs")
      private_key_pem = File.read(fixtures_dir.join("private_key.pem"))
      blob_json = File.read(fixtures_dir.join("webcrypto_blob.json"))
      expected_plaintext = File.read(fixtures_dir.join("webcrypto_plaintext.txt"))

      fixture_service = described_class.new(private_key_pem)
      blob = AiKeypairs::Blob.from_json(blob_json)

      expect(fixture_service.decrypt(blob)).to eq(expected_plaintext)
    end

    it "raises DecryptionError with the underlying failure message when the ciphertext is tampered with (GCM auth failure)" do
      blob_json = encrypt_like_a_browser(plaintext, keypair.public_key_pem)
      parsed = JSON.parse(blob_json)
      tampered_bytes = Base64.strict_decode64(parsed["ciphertext"])
      tampered_bytes = tampered_bytes[0..-2] + (tampered_bytes[-1].ord ^ 0xFF).chr
      parsed["ciphertext"] = Base64.strict_encode64(tampered_bytes)

      blob = AiKeypairs::Blob.from_json(parsed.to_json)

      expect { service.decrypt(blob) }.to raise_error(AiKeypairs::DecryptionError, /failed to decrypt BYOK key blob/)
    end

    it "raises DecryptionError when the wrapped AES key was encrypted to a different keypair" do
      other_keypair = AiKeypairs::KeypairGenerator.call
      blob = AiKeypairs::Blob.from_json(encrypt_like_a_browser(plaintext, other_keypair.public_key_pem))

      expect { service.decrypt(blob) }.to raise_error(AiKeypairs::DecryptionError, /failed to decrypt BYOK key blob/)
    end

    it "raises DecryptionError when the IV is wrong" do
      blob_json = encrypt_like_a_browser(plaintext, keypair.public_key_pem)
      parsed = JSON.parse(blob_json)
      parsed["iv"] = Base64.strict_encode64(OpenSSL::Random.random_bytes(12))

      blob = AiKeypairs::Blob.from_json(parsed.to_json)

      expect { service.decrypt(blob) }.to raise_error(AiKeypairs::DecryptionError, /failed to decrypt BYOK key blob/)
    end

    def wrap_aes_key(aes_key, public_key_pem)
      Base64.strict_encode64(
        OpenSSL::PKey::RSA.new(public_key_pem).encrypt(
          aes_key, { rsa_padding_mode: "oaep", rsa_oaep_md: "SHA256", rsa_mgf1_md: "SHA256" }
        )
      )
    end

    it "raises DecryptionError, with a message naming the reason, when the ciphertext is too short to contain a GCM tag" do
      blob = AiKeypairs::Blob.new(
        wrapped_key: wrap_aes_key(OpenSSL::Random.random_bytes(32), keypair.public_key_pem),
        iv: Base64.strict_encode64(OpenSSL::Random.random_bytes(12)),
        ciphertext: Base64.strict_encode64("short")
      )

      expect { service.decrypt(blob) }.to raise_error(
        AiKeypairs::DecryptionError, /ciphertext too short to contain a GCM tag/
      )
    end

    it "raises DecryptionError when the ciphertext is exactly the tag length (0 bytes of actual ciphertext, still too short to be valid)" do
      blob = AiKeypairs::Blob.new(
        wrapped_key: wrap_aes_key(OpenSSL::Random.random_bytes(32), keypair.public_key_pem),
        iv: Base64.strict_encode64(OpenSSL::Random.random_bytes(12)),
        ciphertext: Base64.strict_encode64("x" * (AiKeypairs::CryptoService::AES_GCM_TAG_BYTES - 1))
      )

      expect { service.decrypt(blob) }.to raise_error(
        AiKeypairs::DecryptionError, /ciphertext too short to contain a GCM tag/
      )
    end

    it "does not raise the length-guard error once ciphertext reaches the tag-length boundary (guard is a strict <, not <=)" do
      aes_key = OpenSSL::Random.random_bytes(32)
      iv = OpenSSL::Random.random_bytes(12)

      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      cipher.key = aes_key
      cipher.iv = iv
      cipher.auth_data = ""
      # Zero-length plaintext: ciphertext_and_tag is exactly AES_GCM_TAG_BYTES
      # long — the exact boundary the `<` guard must let through (and GCM
      # authentication must still pass on an empty payload).
      ciphertext = cipher.update("") + cipher.final
      ciphertext_and_tag = ciphertext + cipher.auth_tag
      expect(ciphertext_and_tag.bytesize).to eq(AiKeypairs::CryptoService::AES_GCM_TAG_BYTES)

      blob = AiKeypairs::Blob.new(
        wrapped_key: wrap_aes_key(aes_key, keypair.public_key_pem),
        iv: Base64.strict_encode64(iv),
        ciphertext: Base64.strict_encode64(ciphertext_and_tag)
      )

      expect(service.decrypt(blob)).to eq("")
    end
  end
end
