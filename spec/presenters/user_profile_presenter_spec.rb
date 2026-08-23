require "rails_helper"

RSpec.describe UserProfilePresenter do
  let(:profile) { build_stubbed(:user_profile) }

  describe "#display_name_or_placeholder" do
    it "returns the display name when set" do
      profile.display_name = "Thorin Oakenshield"
      expect(described_class.new(profile).display_name_or_placeholder).to eq("Thorin Oakenshield")
    end

    it "returns a placeholder when the display name is blank" do
      profile.display_name = ""
      expect(described_class.new(profile).display_name_or_placeholder).to eq("Not set")
    end

    it "returns a placeholder when the display name is nil" do
      profile.display_name = nil
      expect(described_class.new(profile).display_name_or_placeholder).to eq("Not set")
    end
  end

  describe "#hide_ooc?" do
    it "delegates to the model" do
      allow(profile).to receive(:hide_ooc?).and_return(true)
      expect(described_class.new(profile).hide_ooc?).to be(true)
    end

    it "reflects false from the model" do
      allow(profile).to receive(:hide_ooc?).and_return(false)
      expect(described_class.new(profile).hide_ooc?).to be(false)
    end
  end

  describe "#ai_display_preference" do
    it "delegates to the model" do
      allow(profile).to receive(:ai_display_preference).and_return("shown")
      expect(described_class.new(profile).ai_display_preference).to eq("shown")
    end
  end

  describe "#display_name_errors?" do
    it "is false with no errors" do
      expect(described_class.new(profile).display_name_errors?).to be(false)
    end

    it "is true when display_name has an error" do
      profile.errors.add(:display_name, "is too long")
      expect(described_class.new(profile).display_name_errors?).to be(true)
    end
  end

  describe "#display_name_error_message" do
    it "is nil with no errors" do
      expect(described_class.new(profile).display_name_error_message).to be_nil
    end

    it "returns the first display_name error message" do
      profile.errors.add(:display_name, "is too long")
      expect(described_class.new(profile).display_name_error_message).to eq("is too long")
    end
  end
end
