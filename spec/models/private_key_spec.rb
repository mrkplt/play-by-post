require "rails_helper"

RSpec.describe PrivateKey, type: :model do
  describe "connects_to" do
    it "connects to the ai_keys database, not the primary one", db: true do
      expect(described_class.connection_db_config.name).to eq("ai_keys")
    end
  end

  describe "validations" do
    it "requires public_key_id", db: true do
      private_key = build(:private_key, public_key_id: nil)
      expect(private_key).not_to be_valid
      expect(private_key.errors[:public_key_id]).to be_present
    end

    it "requires encrypted_private_key", db: true do
      private_key = build(:private_key, encrypted_private_key: nil)
      expect(private_key).not_to be_valid
      expect(private_key.errors[:encrypted_private_key]).to be_present
    end

    it "requires a unique public_key_id", :ai_credential, db: true do
      public_key = create(:public_key)
      create(:private_key, public_key_id: public_key.id)
      duplicate = build(:private_key, public_key_id: public_key.id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:public_key_id]).to include("has already been taken")
    end
  end

  describe "encryption at rest", :ai_credential do
    it "stores encrypted_private_key as ciphertext in the underlying column, not plaintext", db: true do
      plaintext = "-----BEGIN PRIVATE KEY-----\ntotally-real-private-key\n-----END PRIVATE KEY-----"
      private_key = create(:private_key, encrypted_private_key: plaintext)

      raw_column_value = described_class.connection.select_value(
        "SELECT encrypted_private_key FROM private_keys WHERE id = #{private_key.id}"
      )

      expect(raw_column_value).not_to include(plaintext)
    end

    it "transparently decrypts on read", db: true do
      plaintext = "-----BEGIN PRIVATE KEY-----\ntotally-real-private-key\n-----END PRIVATE KEY-----"
      private_key = create(:private_key, encrypted_private_key: plaintext)

      expect(described_class.find(private_key.id).encrypted_private_key).to eq(plaintext)
    end
  end

  describe "#public_key", :ai_credential do
    it "returns the matching PublicKey by public_key_id", db: true do
      public_key = create(:public_key)
      private_key = create(:private_key, public_key_id: public_key.id)

      expect(private_key.public_key).to eq(public_key)
    end

    it "returns nil when no matching public key row exists", db: true do
      private_key = create(:private_key)
      private_key.update_column(:public_key_id, PublicKey.maximum(:id).to_i + 1_000_000)

      expect(private_key.public_key).to be_nil
    end
  end
end
