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

    it "allows only one keypair per user", db: true do
      user = create(:user)
      create(:ai_keypair, user: user)
      duplicate = build(:ai_keypair, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe "#private_key" do
    it "returns the matching AiPrivateKey by ai_keypair_id", db: true do
      keypair = create(:ai_keypair)
      private_key = create(:ai_private_key, ai_keypair_id: keypair.id)

      expect(keypair.private_key).to eq(private_key)
    end

    it "returns nil when no private key row exists", db: true do
      keypair = create(:ai_keypair)
      expect(keypair.private_key).to be_nil
    end
  end
end
