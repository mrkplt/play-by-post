require "rails_helper"

RSpec.describe AiPrivateKey, type: :model do
  describe "connects_to" do
    it "connects to the ai_keys database, not the primary one", db: true do
      expect(described_class.connection_db_config.name).to eq("ai_keys")
    end
  end

  describe "validations" do
    it "requires ai_keypair_id", db: true do
      private_key = build(:ai_private_key, ai_keypair_id: nil)
      expect(private_key).not_to be_valid
      expect(private_key.errors[:ai_keypair_id]).to be_present
    end

    it "requires encrypted_private_key", db: true do
      private_key = build(:ai_private_key, encrypted_private_key: nil)
      expect(private_key).not_to be_valid
      expect(private_key.errors[:encrypted_private_key]).to be_present
    end

    it "requires a unique ai_keypair_id", db: true do
      keypair = create(:ai_keypair)
      create(:ai_private_key, ai_keypair_id: keypair.id)
      duplicate = build(:ai_private_key, ai_keypair_id: keypair.id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ai_keypair_id]).to include("has already been taken")
    end
  end

  describe "encryption at rest" do
    it "stores encrypted_private_key as ciphertext in the underlying column, not plaintext", db: true do
      plaintext = "-----BEGIN PRIVATE KEY-----\ntotally-real-private-key\n-----END PRIVATE KEY-----"
      private_key = create(:ai_private_key, encrypted_private_key: plaintext)

      raw_column_value = described_class.connection.select_value(
        "SELECT encrypted_private_key FROM ai_private_keys WHERE id = #{private_key.id}"
      )

      expect(raw_column_value).not_to include(plaintext)
    end

    it "transparently decrypts on read", db: true do
      plaintext = "-----BEGIN PRIVATE KEY-----\ntotally-real-private-key\n-----END PRIVATE KEY-----"
      private_key = create(:ai_private_key, encrypted_private_key: plaintext)

      expect(described_class.find(private_key.id).encrypted_private_key).to eq(plaintext)
    end
  end

  describe "#ai_keypair" do
    it "returns the matching AiKeypair by ai_keypair_id", db: true do
      keypair = create(:ai_keypair)
      private_key = create(:ai_private_key, ai_keypair_id: keypair.id)

      expect(private_key.ai_keypair).to eq(keypair)
    end

    it "returns nil when no matching keypair row exists", db: true do
      private_key = create(:ai_private_key)
      private_key.update_column(:ai_keypair_id, AiKeypair.maximum(:id).to_i + 1_000_000)

      expect(private_key.ai_keypair).to be_nil
    end
  end
end
