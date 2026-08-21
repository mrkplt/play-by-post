require "rails_helper"

RSpec.describe "PrivateKeyEncryption" do
  describe PrivateKeyEncryption::UnavailableKeyProvider do
    subject(:provider) { described_class.new }

    it "raises a Configuration error on #encryption_key" do
      expect { provider.encryption_key }.to raise_error(
        ActiveRecord::Encryption::Errors::Configuration, /worker/
      )
    end

    it "raises a Configuration error on #decryption_keys" do
      expect { provider.decryption_keys(instance_double(ActiveRecord::Encryption::Message)) }.to raise_error(
        ActiveRecord::Encryption::Errors::Configuration, /worker/
      )
    end
  end

  describe PrivateKeyEncryption::KeyGenerator do
    it "derives keys from its own key_derivation_salt rather than the global config" do
      generator_a = described_class.new("salt-a")
      generator_b = described_class.new("salt-b")

      key_a = generator_a.derive_key_from("same-password")
      key_b = generator_b.derive_key_from("same-password")

      expect(key_a).not_to eq(key_b)
    end

    it "derives the same key for the same password and salt" do
      generator = described_class.new("a-fixed-salt")

      expect(generator.derive_key_from("same-password")).to eq(generator.derive_key_from("same-password"))
    end
  end

  describe ".build_key_provider" do
    it "returns UnavailableKeyProvider when SECRET_KEY_BASE_DUMMY is set (Docker asset precompile)" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SECRET_KEY_BASE_DUMMY").and_return("1")

      expect(PrivateKeyEncryption.build_key_provider).to be_a(PrivateKeyEncryption::UnavailableKeyProvider)
    end

    it "returns UnavailableKeyProvider when the credential key is not available" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SECRET_KEY_BASE_DUMMY").and_return(nil)
      fake_credentials = instance_double(ActiveSupport::EncryptedConfiguration, key?: false)
      allow(ActiveSupport::EncryptedConfiguration).to receive(:new).and_return(fake_credentials)

      expect(PrivateKeyEncryption.build_key_provider).to be_a(PrivateKeyEncryption::UnavailableKeyProvider)
    end

    it "returns a DerivedSecretKeyProvider when the credential is available", :ai_credential do
      expect(PrivateKeyEncryption.build_key_provider).to be_a(ActiveRecord::Encryption::DerivedSecretKeyProvider)
    end
  end

  describe "KEY_PROVIDER (lazy)" do
    it "is a LazyKeyProvider so class-load never forces a credential read" do
      expect(PrivateKeyEncryption::KEY_PROVIDER).to be_a(PrivateKeyEncryption::LazyKeyProvider)
    end

    it "delegates to the resolved provider on use", :ai_credential do
      # With a working credential stubbed, the lazy wrapper resolves to a real
      # provider and returns a usable encryption key rather than raising.
      expect(PrivateKeyEncryption::KEY_PROVIDER.encryption_key).to be_present
    end
  end
end
