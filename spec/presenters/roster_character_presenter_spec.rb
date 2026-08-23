require "rails_helper"

RSpec.describe RosterCharacterPresenter do
  let(:user) { build_stubbed(:user) }
  let(:character) { build_stubbed(:character, name: "Vex", user: user) }
  let(:helpers) { double("helpers", url_for: "/portrait.jpg") }

  subject(:presenter) { described_class.new(character, removed: false, helpers: helpers) }

  describe "#character_name" do
    it "returns the wrapped character's name" do
      expect(presenter.character_name).to eq("Vex")
    end
  end

  describe "#owner_name" do
    it "delegates to UserPresenter for the owner's display name" do
      allow(user).to receive(:display_name).and_return("Alice")
      expect(presenter.owner_name).to eq("Alice")
    end
  end

  describe "#removed?" do
    it "is true when constructed with removed: true" do
      expect(described_class.new(character, removed: true).removed?).to be(true)
    end

    it "is false when constructed with removed: false" do
      expect(described_class.new(character, removed: false).removed?).to be(false)
    end
  end

  describe "#avatar_tone" do
    it "is :muted when removed" do
      expect(described_class.new(character, removed: true).avatar_tone).to eq(:muted)
    end

    it "is :gold when not removed" do
      expect(described_class.new(character, removed: false).avatar_tone).to eq(:gold)
    end
  end

  describe "#filter_key" do
    it "joins the character name and owner name, lowercased" do
      allow(user).to receive(:display_name).and_return("Alice")
      expect(presenter.filter_key).to eq("vex alice")
    end
  end

  describe "#portrait_url" do
    it "is the character's portrait URL via the injected helpers" do
      allow(character).to receive(:portrait_variant).and_return(:variant)
      expect(presenter.portrait_url).to eq("/portrait.jpg")
    end

    it "is nil when the character has no portrait" do
      allow(character).to receive(:portrait_variant).and_return(nil)
      expect(presenter.portrait_url).to be_nil
    end
  end
end
