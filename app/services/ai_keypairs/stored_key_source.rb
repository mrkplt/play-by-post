# typed: strict

module AiKeypairs
  # AiKeyResolver::KeySource backed by the persisted keypair custody model.
  #
  # For a given owner (User or Game), it loads that owner's AiKeypair, reads the
  # stored browser-sealed envelope (`sealed_key`), pairs it with the owner's
  # private key (AiPrivateKey, worker-only database), and decrypts it via
  # CryptoService back to the plaintext OpenRouter key. Only usable in the
  # worker process — that is the only place with a filesystem path to the
  # private-key database and the encryption credential.
  #
  # Any lookup/decrypt failure raises (per the KeySource contract); the resolver
  # only calls these methods once the owner's ai_key_present? predicate is true,
  # so a missing keypair or envelope here is a genuine inconsistency, surfaced
  # as UnresolvableKey rather than swallowed.
  class StoredKeySource
    extend T::Sig
    include AiKeyResolver::KeySource

    # Raised when an owner is marked as having a key (ai_key_present?) but the
    # stored keypair/envelope/private key needed to decrypt it is missing.
    class UnresolvableKey < StandardError; end

    sig { override.params(user: User).returns(String) }
    def for_user(user)
      decrypt_for(user)
    end

    sig { override.params(game: Game).returns(String) }
    def for_game(game)
      decrypt_for(game)
    end

    private

    # T.untyped owner: User and Game are distinct types with no shared
    # ancestor that expresses "AiKeypair owner"; both reach here only via the
    # typed public methods above, which pin the caller-facing contract.
    sig { params(owner: T.untyped).returns(String) }
    def decrypt_for(owner)
      label = "#{owner.class}##{owner.id}"
      keypair = present_or_raise(AiKeypair.find_by(owner: owner), "no AiKeypair for #{label}")
      blob = present_or_raise(keypair.sealed_blob, "no sealed key for #{label}")
      private_key = present_or_raise(keypair.private_key, "no private key for #{label}")

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
