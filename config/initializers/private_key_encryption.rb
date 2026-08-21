# typed: true

# Keys Active Record Encryption for PrivateKey (app/models/private_key.rb)
# from a BESPOKE encrypted credential — config/ai_private_keys.yml.enc, keyed by
# config/ai_private_keys.key / AI_PRIVATE_KEYS_KEY — deliberately separate from
# RAILS_MASTER_KEY / config/credentials/production.yml.enc. The credential
# file path and env var name are KEPT as-is (a deploy already depends on
# them) even though the Ruby module they key is renamed below.
#
# Worker-only by construction, not by an explicit runtime-mode check: the `web`
# service (docker-compose.yml) is never given AI_PRIVATE_KEYS_KEY or a key file,
# so on web this credential resolves absent and PrivateKey ends up wired to
# PrivateKeyEncryption::UnavailableKeyProvider (below) — encrypt/decrypt raise
# a clear error instead of silently no-oping. PrivateKey's own database
# connection (config/database.yml `ai_keys`) also lives on a volume only the
# `worker` service mounts, so web has no filesystem path to the ciphertext
# rows either — this initializer is the second, independent layer (the key),
# not the only one.
#
# The constant below is ALWAYS defined (never left undeclared): eager loading
# is on in every environment (config/environments/test.rb, production.rb), so
# PrivateKey — and therefore this constant — loads on every boot, including
# web's. Leaving it undefined when the credential is absent would be a
# NameError at eager-load time on web, not a controlled failure at the one
# call site (worker) that actually needs it.
#
# Resolution is LAZY: KEY_PROVIDER is a wrapper that defers reading the
# credential until a PrivateKey row is actually encrypted or decrypted —
# matching how the rest of the app treats credentials (read on use, never
# forced open at boot). This is what lets `web`, CI, and a fresh clone boot
# with the credential absent (falling through to UnavailableKeyProvider only
# if something truly touches ciphertext) instead of failing at eager-load.
module PrivateKeyEncryption
  # Raises with a clear message instead of encrypting/decrypting with no key,
  # so a process without the credential (i.e. `web`) fails loudly and
  # specifically the moment anything tries to touch PrivateKey ciphertext,
  # rather than booting successfully and failing mysteriously later.
  class UnavailableKeyProvider < ActiveRecord::Encryption::KeyProvider
    def initialize
      super([])
    end

    def encryption_key
      raise ActiveRecord::Encryption::Errors::Configuration,
            "PrivateKey encryption key is not available in this process. " \
            "config/ai_private_keys.yml.enc / AI_PRIVATE_KEYS_KEY is only " \
            "supplied to the worker process — PrivateKey must not be " \
            "read or written outside it."
    end

    def decryption_keys(_encrypted_message)
      raise ActiveRecord::Encryption::Errors::Configuration,
            "PrivateKey encryption key is not available in this process. " \
            "config/ai_private_keys.yml.enc / AI_PRIVATE_KEYS_KEY is only " \
            "supplied to the worker process — PrivateKey must not be " \
            "read or written outside it."
    end
  end

  # Derives from this credential's OWN key_derivation_salt instead of the
  # app-wide ActiveRecord::Encryption.config.key_derivation_salt (which stays
  # unset — nothing else in this app uses `encrypts`). Rails'
  # DerivedSecretKeyProvider accepts a custom key_generator: for exactly this.
  class KeyGenerator < ActiveRecord::Encryption::KeyGenerator
    def initialize(key_derivation_salt)
      super()
      @key_derivation_salt = key_derivation_salt
    end

    private

    attr_reader :key_derivation_salt
  end

  # Defers building the real key provider until the first encrypt/decrypt call,
  # so class-load/boot never reads the credential. Delegates the KeyProvider
  # interface (encryption_key / decryption_keys) to the memoized real provider.
  class LazyKeyProvider < ActiveRecord::Encryption::KeyProvider
    def initialize
      super([])
    end

    def encryption_key
      resolved.encryption_key
    end

    def decryption_keys(encrypted_message)
      resolved.decryption_keys(encrypted_message)
    end

    private

    def resolved
      @resolved ||= PrivateKeyEncryption.build_key_provider
    end
  end

  # Guarded for Docker's asset-precompile boot (SECRET_KEY_BASE_DUMMY): that
  # build has no credentials key material of any kind and must not attempt
  # to read one.
  def self.build_key_provider
    return UnavailableKeyProvider.new if ENV["SECRET_KEY_BASE_DUMMY"]

    # Built directly (not via Rails.application.encrypted) so
    # raise_if_missing_key can be pinned to false regardless of
    # config.require_master_key — on `web`, where this key is never
    # supplied, absence must fall through to UnavailableKeyProvider, not a
    # boot failure.
    credentials = ActiveSupport::EncryptedConfiguration.new(
      config_path: Rails.root.join("config/ai_private_keys.yml.enc"),
      key_path: Rails.root.join("config/ai_private_keys.key"),
      env_key: "AI_PRIVATE_KEYS_KEY",
      raise_if_missing_key: false
    )

    return UnavailableKeyProvider.new unless credentials.key?

    # #config (not the dynamic #active_record_encryption accessor): a real
    # declared method, so this keeps type-checking meaningful around it
    # instead of resolving through EncryptedConfiguration#method_missing,
    # which Sorbet cannot see through statically.
    encryption_config = credentials.config.fetch(:active_record_encryption)

    ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
      [ encryption_config.fetch(:primary_key) ],
      key_generator: KeyGenerator.new(encryption_config.fetch(:key_derivation_salt))
    )
  end

  # The provider handed to `encrypts` — lazy, so boot never forces a
  # credential read (see the module comment above).
  KEY_PROVIDER = LazyKeyProvider.new
end
