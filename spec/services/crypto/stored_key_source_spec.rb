require "rails_helper"

RSpec.describe Crypto::StoredKeySource, :ai_credential do
  subject(:source) { described_class.new }

  let(:openrouter_key) { "sk-or-v1-fake-openrouter-key-1234567890" }
  let(:value_type) { described_class::OPENROUTER_KEY_VALUE_TYPE }

  # Builds a full custody record for `owner`: a generated keypair (public key in
  # the primary db, private key encrypted in the ai_keys db) with the owner's
  # OpenRouter key sealed to it, exactly as the browser would.
  def seal_key_for(owner, plaintext)
    generated = Crypto::KeypairGenerator.call
    public_key = create(:public_key, public_key: generated.public_key_pem, fingerprint: generated.fingerprint)
    encrypted_value = create(
      :encrypted_value,
      owner: owner,
      value_type: value_type,
      public_key: public_key,
      sealed_value: encrypt_like_a_browser(plaintext, generated.public_key_pem)
    )
    create(:private_key, public_key_id: public_key.id, encrypted_private_key: generated.private_key_pem)
    encrypted_value
  end

  describe "#for_user" do
    it "decrypts the user's stored envelope back to their OpenRouter key", db: true do
      user = create(:user)
      seal_key_for(user, openrouter_key)

      expect(source.for_user(user)).to eq(openrouter_key)
    end

    it "raises UnresolvableKey when the user has no EncryptedValue", db: true do
      user = create(:user)

      expect { source.for_user(user) }
        .to raise_error(described_class::UnresolvableKey, /no EncryptedValue/)
    end

    it "raises UnresolvableKey when the EncryptedValue has no sealed value", db: true do
      user = create(:user)
      create(:encrypted_value, owner: user, value_type: value_type, sealed_value: nil)

      expect { source.for_user(user) }
        .to raise_error(described_class::UnresolvableKey, /no sealed value/)
    end

    it "raises UnresolvableKey when the private key is missing", db: true do
      user = create(:user)
      generated = Crypto::KeypairGenerator.call
      public_key = create(:public_key, public_key: generated.public_key_pem, fingerprint: generated.fingerprint)
      create(
        :encrypted_value,
        owner: user,
        value_type: value_type,
        public_key: public_key,
        sealed_value: encrypt_like_a_browser(openrouter_key, generated.public_key_pem)
      )

      expect { source.for_user(user) }
        .to raise_error(described_class::UnresolvableKey, /no private key/)
    end
  end

  describe "#for_game" do
    it "decrypts the game's stored envelope back to its OpenRouter key", db: true do
      game = create(:game)
      seal_key_for(game, openrouter_key)

      expect(source.for_game(game)).to eq(openrouter_key)
    end

    it "resolves the game's key independently of any user's key", db: true do
      user = create(:user)
      game = create(:game)
      seal_key_for(user, "sk-or-user-key")
      seal_key_for(game, "sk-or-game-key")

      expect(source.for_game(game)).to eq("sk-or-game-key")
    end
  end
end
