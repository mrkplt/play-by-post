# typed: false

# Encryption round-trip specs for AiPrivateKey need a WORKING encryption key.
# The real credential (config/ai_private_keys.yml.enc) is keyed by a gitignored
# key that isn't present on a fresh clone or CI — and, like the rest of the app,
# nothing outside these specs should depend on reading it. So instead of
# providing the real credential, these specs stub in a throwaway
# DerivedSecretKeyProvider built from a random key, exercising the real
# Active Record Encryption round trip without the real secret.
#
# AiPrivateKeyEncryption::KEY_PROVIDER resolves lazily and memoizes, so the stub
# is installed on AiPrivateKeyEncryption.build_key_provider (what the lazy
# wrapper calls) and the memoization is reset before and after, keeping the
# process-wide UnavailableKeyProvider default intact for every other spec.
module AiPrivateKeyCredential
  def self.working_key_provider
    ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
      [ SecureRandom.hex(32) ],
      key_generator: AiPrivateKeyEncryption::KeyGenerator.new(SecureRandom.hex(32))
    )
  end

  def self.reset_lazy_memoization!
    provider = AiPrivateKeyEncryption::KEY_PROVIDER
    provider.instance_variable_set(:@resolved, nil) if provider.instance_variable_defined?(:@resolved)
  end
end

RSpec.configure do |config|
  # `before`/`after` (not `around`) so the partial double is set up inside the
  # per-test rspec-mocks lifecycle. Reset the lazy memoization on both sides so
  # the stub is what gets resolved during the example, and the process-wide
  # default is restored for every other spec afterwards.
  config.before(:each, :ai_credential) do
    AiPrivateKeyCredential.reset_lazy_memoization!
    allow(AiPrivateKeyEncryption).to receive(:build_key_provider)
      .and_return(AiPrivateKeyCredential.working_key_provider)
  end

  config.after(:each, :ai_credential) do
    AiPrivateKeyCredential.reset_lazy_memoization!
  end
end
