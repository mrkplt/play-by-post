require "rails_helper"

RSpec.describe AiKeypairGenerationJob, type: :job do
  describe "#perform" do
    it "creates an AiKeypair and matching AiPrivateKey for the owner", :ai_credential, db: true do
      user = create(:user)

      expect {
        described_class.new.perform(owner_type: "User", owner_id: user.id)
      }.to change(AiKeypair, :count).by(1).and change(AiPrivateKey, :count).by(1)

      keypair = AiKeypair.find_by(owner: user)
      expect(keypair).to be_present
      expect(keypair.private_key).to be_present
    end

    it "generates a public key the private key actually pairs with", :ai_credential, db: true do
      user = create(:user)
      described_class.new.perform(owner_type: "User", owner_id: user.id)

      keypair = AiKeypair.find_by(owner: user)
      public_key = OpenSSL::PKey::RSA.new(keypair.public_key)
      private_key = OpenSSL::PKey::RSA.new(T.must(keypair.private_key).encrypted_private_key)

      expect(private_key.n).to eq(public_key.n)
    end

    it "supports a Game owner (the GM fallback key)", :ai_credential, db: true do
      game = create(:game)

      described_class.new.perform(owner_type: "Game", owner_id: game.id)

      expect(AiKeypair.find_by(owner: game)).to be_present
    end

    it "is idempotent — does nothing if a keypair already exists for the owner", :ai_credential, db: true do
      user = create(:user)
      existing = create(:ai_keypair, owner: user)

      expect {
        described_class.new.perform(owner_type: "User", owner_id: user.id)
      }.not_to change(AiKeypair, :count)

      expect(AiKeypair.find_by(owner: user)).to eq(existing)
    end

    it "still generates for this owner when a keypair exists only for a different owner", :ai_credential, db: true do
      other_user = create(:user)
      create(:ai_keypair, owner: other_user)
      user = create(:user)

      expect {
        described_class.new.perform(owner_type: "User", owner_id: user.id)
      }.to change(AiKeypair, :count).by(1)

      expect(AiKeypair.find_by(owner: user)).to be_present
    end

    it "checks owner_type as well as owner_id — a Game keypair does not block a User with the same numeric id", :ai_credential, db: true do
      game = create(:game)
      create(:ai_keypair, owner: game)
      user = create(:user, id: game.id)

      expect {
        described_class.new.perform(owner_type: "User", owner_id: user.id)
      }.to change(AiKeypair, :count).by(1)

      expect(AiKeypair.find_by(owner_type: "User", owner_id: user.id)).to be_present
    end

    it "does not leak private key material onto the AiKeypair row", :ai_credential, db: true do
      user = create(:user)
      described_class.new.perform(owner_type: "User", owner_id: user.id)

      keypair = AiKeypair.find_by(owner: user)
      expect(keypair.public_key).not_to include("PRIVATE KEY")
    end

    it "stores the fingerprint as the SHA-256 hex digest of the public key DER", :ai_credential, db: true do
      user = create(:user)
      described_class.new.perform(owner_type: "User", owner_id: user.id)

      keypair = AiKeypair.find_by(owner: user)
      public_key = OpenSSL::PKey::RSA.new(keypair.public_key)
      expect(keypair.fingerprint).to eq(OpenSSL::Digest::SHA256.hexdigest(public_key.public_key.to_der))
    end
  end
end
