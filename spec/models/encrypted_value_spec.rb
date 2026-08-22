require "rails_helper"

RSpec.describe EncryptedValue, type: :model do
  describe "validations" do
    it "requires a value_type", db: true do
      encrypted_value = build(:encrypted_value, value_type: nil)
      expect(encrypted_value).not_to be_valid
      expect(encrypted_value.errors[:value_type]).to be_present
    end

    it "allows only one EncryptedValue per owner per value_type", db: true do
      user = create(:user)
      create(:encrypted_value, owner: user, value_type: "openrouter_key")
      duplicate = build(:encrypted_value, owner: user, value_type: "openrouter_key")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:owner_id]).to be_present
    end

    it "allows the same owner to hold EncryptedValues of different value_types", db: true do
      user = create(:user)
      create(:encrypted_value, owner: user, value_type: "openrouter_key")
      other = build(:encrypted_value, owner: user, value_type: "something_else")

      expect(other).to be_valid
    end

    it "rejects a Game as owner — only a person can own a key", db: true do
      game = create(:game)
      game_value = build(:encrypted_value, owner: game, value_type: "openrouter_key")

      expect(game_value).not_to be_valid
      expect(game_value.errors[:owner_type]).to be_present
    end
  end

  describe "#private_key" do
    it "returns the private key belonging to this value's public key", :ai_credential, db: true do
      encrypted_value = create(:encrypted_value)
      private_key = create(:private_key, public_key_id: encrypted_value.public_key_id)

      expect(encrypted_value.private_key).to eq(private_key)
    end

    it "returns nil when no private key row exists", db: true do
      encrypted_value = create(:encrypted_value)
      expect(encrypted_value.private_key).to be_nil
    end
  end

  describe "#sealed_blob" do
    it "returns nil when no value has been sealed", db: true do
      encrypted_value = create(:encrypted_value, sealed_value: nil)
      expect(encrypted_value.sealed_blob).to be_nil
    end

    it "parses the stored envelope JSON into a Blob", db: true do
      envelope = { wrapped_key: "d2s=", iv: "aXY=", ciphertext: "Y3Q=" }.to_json
      encrypted_value = create(:encrypted_value, sealed_value: envelope)

      blob = encrypted_value.sealed_blob
      expect(blob).to be_a(Crypto::Blob)
      expect(blob&.wrapped_key).to eq("d2s=")
      expect(blob&.iv).to eq("aXY=")
      expect(blob&.ciphertext).to eq("Y3Q=")
    end
  end
end
