# typed: strict

module AiKeypairs
  # The JSON shape browsers submit to be decrypted by CryptoService#decrypt —
  # see CryptoService's class comment for exactly how the browser must
  # produce each field (WebCrypto SubtleCrypto, hybrid AES-GCM + RSA-OAEP-256
  # envelope, base64-encoded).
  class Blob < T::Struct
    extend T::Sig

    const :wrapped_key, String
    const :iv, String
    const :ciphertext, String

    sig { params(json: String).returns(Blob) }
    def self.from_json(json)
      parsed = JSON.parse(json)
      new(
        wrapped_key: T.cast(parsed.fetch("wrapped_key"), String),
        iv: T.cast(parsed.fetch("iv"), String),
        ciphertext: T.cast(parsed.fetch("ciphertext"), String)
      )
    rescue JSON::ParserError, KeyError => e
      raise DecryptionError, "malformed BYOK key blob: #{e.message}"
    end
  end
end
