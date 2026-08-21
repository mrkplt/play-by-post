require "rails_helper"

RSpec.describe UserByokKeyPresenter do
  describe "#present?" do
    it "returns true when the model reports a key present" do
      user = build_stubbed(:user)
      allow(user).to receive(:ai_key_present?).and_return(true)

      expect(described_class.new(user).present?).to be(true)
    end

    it "returns false when the model reports no key present" do
      user = build_stubbed(:user)
      allow(user).to receive(:ai_key_present?).and_return(false)

      expect(described_class.new(user).present?).to be(false)
    end
  end

  describe "#public_key_pem", :db do
    let(:user) { create(:user) }

    it "returns the public key PEM when a keypair exists" do
      keypair = create(:ai_keypair, owner: user)
      expect(described_class.new(user).public_key_pem).to eq(keypair.public_key)
    end

    it "returns nil when no keypair has been generated yet" do
      expect(described_class.new(user).public_key_pem).to be_nil
    end
  end
end
