require "rails_helper"

RSpec.describe AiKeypairs::StoredKeySource, :ai_credential do
  subject(:source) { described_class.new }

  let(:openrouter_key) { "sk-or-v1-fake-openrouter-key-1234567890" }

  # Builds a full custody record for `owner`: a generated keypair (public key in
  # the primary db, private key encrypted in the ai_keys db) with the owner's
  # OpenRouter key sealed to it, exactly as the browser would.
  def seal_key_for(owner, plaintext)
    generated = AiKeypairs::KeypairGenerator.call
    keypair = create(
      :ai_keypair,
      owner: owner,
      public_key: generated.public_key_pem,
      fingerprint: generated.fingerprint,
      sealed_key: encrypt_like_a_browser(plaintext, generated.public_key_pem)
    )
    create(:ai_private_key, ai_keypair_id: keypair.id, encrypted_private_key: generated.private_key_pem)
    keypair
  end

  describe "#for_user" do
    it "decrypts the user's stored envelope back to their OpenRouter key", db: true do
      user = create(:user)
      seal_key_for(user, openrouter_key)

      expect(source.for_user(user)).to eq(openrouter_key)
    end

    it "raises UnresolvableKey when the user has no keypair", db: true do
      user = create(:user)

      expect { source.for_user(user) }
        .to raise_error(described_class::UnresolvableKey, /no AiKeypair/)
    end

    it "raises UnresolvableKey when the keypair has no sealed key", db: true do
      user = create(:user)
      create(:ai_keypair, owner: user, sealed_key: nil)

      expect { source.for_user(user) }
        .to raise_error(described_class::UnresolvableKey, /no sealed key/)
    end

    it "raises UnresolvableKey when the private key is missing", db: true do
      user = create(:user)
      generated = AiKeypairs::KeypairGenerator.call
      create(
        :ai_keypair,
        owner: user,
        public_key: generated.public_key_pem,
        fingerprint: generated.fingerprint,
        sealed_key: encrypt_like_a_browser(openrouter_key, generated.public_key_pem)
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
