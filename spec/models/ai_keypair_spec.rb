require "rails_helper"

RSpec.describe AiKeypair, type: :model do
  describe "validations" do
    it "requires a public_key", db: true do
      keypair = build(:ai_keypair, public_key: nil)
      expect(keypair).not_to be_valid
      expect(keypair.errors[:public_key]).to be_present
    end

    it "requires a fingerprint", db: true do
      keypair = build(:ai_keypair, fingerprint: nil)
      expect(keypair).not_to be_valid
      expect(keypair.errors[:fingerprint]).to be_present
    end

    it "requires a unique fingerprint", db: true do
      existing = create(:ai_keypair)
      keypair = build(:ai_keypair, fingerprint: existing.fingerprint)
      expect(keypair).not_to be_valid
      expect(keypair.errors[:fingerprint]).to include("has already been taken")
    end

    it "allows only one keypair per owner", db: true do
      user = create(:user)
      create(:ai_keypair, owner: user)
      duplicate = build(:ai_keypair, owner: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:owner_id]).to be_present
    end

    it "allows a game to own its own keypair alongside a user's", db: true do
      user = create(:user)
      create(:ai_keypair, owner: user)
      game_keypair = build(:ai_keypair, :for_game)
      expect(game_keypair).to be_valid
    end
  end

  describe "#private_key" do
    it "returns the matching AiPrivateKey by ai_keypair_id", :ai_credential, db: true do
      keypair = create(:ai_keypair)
      private_key = create(:ai_private_key, ai_keypair_id: keypair.id)

      expect(keypair.private_key).to eq(private_key)
    end

    it "returns nil when no private key row exists", db: true do
      keypair = create(:ai_keypair)
      expect(keypair.private_key).to be_nil
    end
  end

  describe "#sealed_blob" do
    it "returns nil when no key has been sealed", db: true do
      keypair = create(:ai_keypair, sealed_key: nil)
      expect(keypair.sealed_blob).to be_nil
    end

    it "parses the stored envelope JSON into a Blob", db: true do
      envelope = { wrapped_key: "d2s=", iv: "aXY=", ciphertext: "Y3Q=" }.to_json
      keypair = create(:ai_keypair, sealed_key: envelope)

      blob = keypair.sealed_blob
      expect(blob).to be_a(AiKeypairs::Blob)
      expect(blob&.wrapped_key).to eq("d2s=")
      expect(blob&.iv).to eq("aXY=")
      expect(blob&.ciphertext).to eq("Y3Q=")
    end
  end
end
