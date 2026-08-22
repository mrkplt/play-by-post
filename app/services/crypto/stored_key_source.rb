# typed: strict

module Crypto
  # AiKeyResolver::KeySource backed by the persisted EncryptedValue custody
  # model, resolving the "openrouter_key" EncryptedValue for a given owner.
  #
  # For a given User owner, it loads that person's "openrouter_key"
  # EncryptedValue, reads the stored browser-sealed envelope (`sealed_value`),
  # pairs it with the value's dedicated private key (PrivateKey, worker-only
  # database, reached via the EncryptedValue's PublicKey), and decrypts it via
  # CryptoService back to the plaintext OpenRouter key. Only usable in the
  # worker process — that is the only place with a filesystem path to the
  # private-key database and the encryption credential.
  #
  # Any lookup/decrypt failure raises (per the KeySource contract); the resolver
  # only calls these methods once the owner's ai_key_present? predicate is true,
  # so a missing EncryptedValue or envelope here is a genuine inconsistency,
  # surfaced as UnresolvableKey rather than swallowed.
  class StoredKeySource
    extend T::Sig
    include AiKeyResolver::KeySource

    # The EncryptedValue#value_type this KeySource resolves. AiKeyResolver
    # (the BYOK OpenRouter-key consumer) is the only current caller — a future
    # EncryptedValue consumer would use its own value_type and, if the lookup
    # shape differs, its own KeySource-like adapter.
    OPENROUTER_KEY_VALUE_TYPE = "openrouter_key"

    # Raised when an owner is marked as having a key (ai_key_present?) but the
    # stored EncryptedValue/envelope/private key needed to decrypt it is missing.
    class UnresolvableKey < StandardError; end

    sig { override.params(user: User).returns(String) }
    def for_user(user)
      decrypt_for(user)
    end

    private

    sig { params(owner: User).returns(String) }
    def decrypt_for(owner)
      label = "#{owner.class}##{owner.id}"
      encrypted_value = present_or_raise(
        EncryptedValue.find_by(owner: owner, value_type: OPENROUTER_KEY_VALUE_TYPE),
        "no EncryptedValue for #{label}"
      )
      blob = present_or_raise(encrypted_value.sealed_blob, "no sealed value for #{label}")
      private_key = present_or_raise(encrypted_value.private_key, "no private key for #{label}")

      CryptoService.new(private_key.encrypted_private_key).decrypt(blob)
    end

    # Returns value if present, else raises UnresolvableKey with message — keeps
    # decrypt_for a short sequence of resolve-or-fail steps.
    sig { params(value: T.untyped, message: String).returns(T.untyped) }
    def present_or_raise(value, message)
      raise UnresolvableKey, message if value.nil?

      value
    end
  end
end
