require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "validations" do
    it "requires an email" do
      expect(build(:invitation, email: nil)).not_to be_valid
    end

    it "requires a valid email format" do
      expect(build(:invitation, email: "notanemail")).not_to be_valid
    end

    it "is valid with required attributes" do
      expect(build(:invitation)).to be_valid
    end
  end

  describe "token generation" do
    it "generates a token before validation" do
      invitation = build(:invitation, token: nil)
      invitation.valid?
      expect(invitation.token).to be_present
    end

    it "does not overwrite an existing token" do
      invitation = build(:invitation, token: "custom-token")
      invitation.valid?
      expect(invitation.token).to eq("custom-token")
    end
  end

  describe "#accepted?" do
    it "returns false when not accepted" do
      expect(build(:invitation).accepted?).to be false
    end

    it "returns true when accepted" do
      expect(build(:invitation, :accepted).accepted?).to be true
    end
  end
end
