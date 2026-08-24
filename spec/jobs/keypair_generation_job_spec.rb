require "rails_helper"

RSpec.describe KeypairGenerationJob, type: :job do
  let(:value_type) { "openrouter_key" }

  describe "#perform" do
    it "creates an EncryptedValue with its own PublicKey and PrivateKey for the owner", :ai_credential, db: true do
      user = create(:user)

      expect {
        described_class.new.perform(owner_type: "User", owner_id: user.id, value_type: value_type)
      }.to change(EncryptedValue, :count).by(1).and change(PublicKey, :count).by(1).and change(PrivateKey, :count).by(1)

      encrypted_value = EncryptedValue.find_by(owner: user, value_type: value_type)
      expect(encrypted_value).to be_present
      expect(encrypted_value.public_key).to be_present
      expect(encrypted_value.private_key).to be_present
    end

    it "generates a public key the private key actually pairs with", :ai_credential, db: true do
      user = create(:user)
      described_class.new.perform(owner_type: "User", owner_id: user.id, value_type: value_type)

      encrypted_value = EncryptedValue.find_by(owner: user, value_type: value_type)
      public_key = OpenSSL::PKey::RSA.new(encrypted_value.public_key.public_key)
      private_key = OpenSSL::PKey::RSA.new(T.must(encrypted_value.private_key).encrypted_private_key)

      expect(private_key.n).to eq(public_key.n)
    end

    it "is idempotent — does nothing if an EncryptedValue already exists for the owner+value_type", :ai_credential, db: true do
      user = create(:user)
      existing = create(:encrypted_value, owner: user, value_type: value_type)

      expect {
        described_class.new.perform(owner_type: "User", owner_id: user.id, value_type: value_type)
      }.not_to change(EncryptedValue, :count)

      expect(EncryptedValue.find_by(owner: user, value_type: value_type)).to eq(existing)
    end

    it "still generates for this value_type when the owner has an EncryptedValue of a different value_type", :ai_credential, db: true do
      user = create(:user)
      create(:encrypted_value, owner: user, value_type: "something_else")

      expect {
        described_class.new.perform(owner_type: "User", owner_id: user.id, value_type: value_type)
      }.to change(EncryptedValue, :count).by(1)

      expect(EncryptedValue.find_by(owner: user, value_type: value_type)).to be_present
    end

    it "still generates for this owner when an EncryptedValue exists only for a different owner", :ai_credential, db: true do
      other_user = create(:user)
      create(:encrypted_value, owner: other_user, value_type: value_type)
      user = create(:user)

      expect {
        described_class.new.perform(owner_type: "User", owner_id: user.id, value_type: value_type)
      }.to change(EncryptedValue, :count).by(1)

      expect(EncryptedValue.find_by(owner: user, value_type: value_type)).to be_present
    end

    it "does not leak private key material onto the PublicKey row", :ai_credential, db: true do
      user = create(:user)
      described_class.new.perform(owner_type: "User", owner_id: user.id, value_type: value_type)

      encrypted_value = EncryptedValue.find_by(owner: user, value_type: value_type)
      expect(encrypted_value.public_key.public_key).not_to include("PRIVATE KEY")
    end

    it "stores the fingerprint as the SHA-256 hex digest of the public key DER", :ai_credential, db: true do
      user = create(:user)
      described_class.new.perform(owner_type: "User", owner_id: user.id, value_type: value_type)

      encrypted_value = EncryptedValue.find_by(owner: user, value_type: value_type)
      public_key = OpenSSL::PKey::RSA.new(encrypted_value.public_key.public_key)
      expect(encrypted_value.public_key.fingerprint).to eq(OpenSSL::Digest::SHA256.hexdigest(public_key.public_key.to_der))
    end
  end
end
