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

  describe "#ai_display_preference" do
    it "defaults to tagged" do
      expect(build(:user_profile).ai_display_preference).to eq("tagged")
    end

    it "accepts shown" do
      profile = build(:user_profile, ai_display_preference: :shown)
      expect(profile.shown?).to be true
    end

    it "accepts tagged" do
      profile = build(:user_profile, ai_display_preference: :tagged)
      expect(profile.tagged?).to be true
    end

    it "accepts hidden" do
      profile = build(:user_profile, ai_display_preference: :hidden)
      expect(profile.hidden?).to be true
    end

    it "rejects an unrecognized value" do
      expect { build(:user_profile, ai_display_preference: :invisible) }.to raise_error(ArgumentError)
    end
  end

  describe "#update_display_name" do
    it "assigns and persists the new display name, returning true on success" do
      profile = create(:user_profile, display_name: "Old Name")

      expect(profile.update_display_name("New Name")).to be true
      expect(profile.reload.display_name).to eq("New Name")
    end

    it "returns false and does not persist when the new name is invalid" do
      profile = create(:user_profile, display_name: "Old Name")

      expect(profile.update_display_name("a" * 101)).to be false
      expect(profile.reload.display_name).to eq("Old Name")
    end
  end
end
