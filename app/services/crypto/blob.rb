# typed: strict

module Crypto
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
    rescue JSON::ParserError, KeyError => error
      raise DecryptionError, "malformed sealed value blob: #{error.message}"
    end

    # Builds a Blob from an ActionController::Parameters already permitted to
    # exactly these three keys (e.g. Profiles::ByokKeysController's
    # seal/replace endpoint) — the strong-parameters counterpart to
    # .from_json's raw-JSON constructor. Raises KeyError (same as .from_json)
    # on a missing field, so callers handle both the same way.
    sig { params(permitted_params: ActionController::Parameters).returns(Blob) }
    def self.from_params(permitted_params)
      new(
        wrapped_key: T.cast(permitted_params.fetch(:wrapped_key), String),
        iv: T.cast(permitted_params.fetch(:iv), String),
        ciphertext: T.cast(permitted_params.fetch(:ciphertext), String)
      )
    end
  end
end
