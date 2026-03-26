require "rails_helper"

RSpec.describe UserProfile, type: :model do
  describe "validations" do
    it "is valid with a display name" do
      expect(build(:user_profile)).to be_valid
    end

    it "allows blank display name" do
      expect(build(:user_profile, display_name: "")).to be_valid
    end

    it "rejects display name over 100 characters" do
      expect(build(:user_profile, display_name: "a" * 101)).not_to be_valid
    end
  end

  describe "predicates" do
    it "#display_name_set? returns true when display name is present" do
      expect(build(:user_profile, display_name: "Test").display_name_set?).to be true
    end

    it "#display_name_set? returns false when display name is blank" do
      expect(build(:user_profile, display_name: "").display_name_set?).to be false
    end

    it "#display_name_set? returns false when display name is nil" do
      expect(build(:user_profile, display_name: nil).display_name_set?).to be false
    end
  end
end
