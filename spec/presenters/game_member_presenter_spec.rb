require "rails_helper"

RSpec.describe GameMemberPresenter do
  let(:user) { build_stubbed(:user) }
  let(:member) { build_stubbed(:game_member, user: user) }

  describe "#display_name" do
    it "delegates to UserPresenter's display_name_or_email" do
      presenter = described_class.new(member)
      expect(presenter.display_name).to eq(UserPresenter.new(user).display_name_or_email)
    end
  end

  describe "#character_name" do
    it "returns the injected character_name" do
      presenter = described_class.new(member, character_name: "Thorin Oakenshield")
      expect(presenter.character_name).to eq("Thorin Oakenshield")
    end

    it "is nil when no character_name was supplied" do
      presenter = described_class.new(member)
      expect(presenter.character_name).to be_nil
    end
  end

  describe "#active?" do
    it "delegates to the model" do
      allow(member).to receive(:active?).and_return(true)
      expect(described_class.new(member).active?).to be(true)
    end
  end

  describe "#removed?" do
    it "delegates to the model" do
      allow(member).to receive(:removed?).and_return(true)
      expect(described_class.new(member).removed?).to be(true)
    end
  end

  it "delegates model methods, e.g. id" do
    member = build_stubbed(:game_member, id: 7, user: user)
    expect(described_class.new(member).id).to eq(7)
  end
end
