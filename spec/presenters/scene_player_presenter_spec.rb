require "rails_helper"

RSpec.describe ScenePlayerPresenter do
  let(:user) { build_stubbed(:user) }

  describe "#display_name_or_email" do
    it "returns the display name when set" do
      allow(user).to receive(:display_name).and_return("Lady Ashford")
      presenter = described_class.new(user, characters: [])
      expect(presenter.display_name_or_email).to eq("Lady Ashford")
    end

    it "falls back to the email prefix" do
      user = build_stubbed(:user, email: "jane@example.com")
      allow(user).to receive(:display_name).and_return(nil)
      presenter = described_class.new(user, characters: [])
      expect(presenter.display_name_or_email).to eq("jane")
    end
  end

  describe "#characters" do
    it "wraps each character in a CharacterPresenter" do
      character = build_stubbed(:character, user: user)
      presenter = described_class.new(user, characters: [ character ])
      expect(presenter.characters).to all(be_a(CharacterPresenter))
    end
  end

  describe "#characters?" do
    it "is false with no characters" do
      expect(described_class.new(user, characters: []).characters?).to be(false)
    end

    it "is true with characters" do
      character = build_stubbed(:character, user: user)
      expect(described_class.new(user, characters: [ character ]).characters?).to be(true)
    end
  end
end
