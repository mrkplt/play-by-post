require "rails_helper"

RSpec.describe PublicKey, type: :model do
  describe "validations" do
    it "requires a public_key", db: true do
      public_key = build(:public_key, public_key: nil)
      expect(public_key).not_to be_valid
      expect(public_key.errors[:public_key]).to be_present
    end

    it "requires a fingerprint", db: true do
      public_key = build(:public_key, fingerprint: nil)
      expect(public_key).not_to be_valid
      expect(public_key.errors[:fingerprint]).to be_present
    end

    it "requires a unique fingerprint", db: true do
      existing = create(:public_key)
      public_key = build(:public_key, fingerprint: existing.fingerprint)
      expect(public_key).not_to be_valid
      expect(public_key.errors[:fingerprint]).to include("has already been taken")
    end
  end

  describe "#private_key" do
    it "returns the matching PrivateKey by public_key_id", :ai_credential, db: true do
      public_key = create(:public_key)
      private_key = create(:private_key, public_key_id: public_key.id)

      expect(public_key.private_key).to eq(private_key)
    end

    it "returns nil when no private key row exists", db: true do
      public_key = create(:public_key)
      expect(public_key.private_key).to be_nil
    end
  end
end
