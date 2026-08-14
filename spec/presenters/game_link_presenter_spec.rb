require "rails_helper"

RSpec.describe GameLinkPresenter do
  let(:game_link) { build_stubbed(:game_link, description: "Map") }
  let(:policy) { instance_double(GameLinkPolicy, manage?: true) }
  let(:game_policy) { instance_double(GamePolicy, manage?: true) }

  subject(:presenter) { described_class.new(game_link, policy: policy, game_policy: game_policy) }

  describe "#can_manage?" do
    it "is true when the injected policy allows management" do
      allow(policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage?).to be(true)
    end

    it "is false when the injected policy disallows management" do
      allow(policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage?).to be(false)
    end
  end

  describe "#can_manage_game?" do
    it "is true when the injected game policy allows management" do
      allow(game_policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage_game?).to be(true)
    end

    it "is false when the injected game policy disallows management" do
      allow(game_policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage_game?).to be(false)
    end
  end

  describe "#new_record?" do
    it "is true for an unpersisted link" do
      expect(described_class.new(GameLink.new, policy: policy, game_policy: game_policy).new_record?).to be(true)
    end

    it "is false for a persisted link" do
      expect(presenter.new_record?).to be(false)
    end
  end

  describe "#id" do
    it "returns the underlying id" do
      expect(presenter.id).to eq(game_link.id)
    end
  end

  describe "#description" do
    it "returns the underlying description" do
      expect(presenter.description).to eq("Map")
    end
  end

  describe "#errors?" do
    it "is false with no errors" do
      expect(presenter.errors?).to be(false)
    end

    it "is true when the link has errors" do
      game_link.errors.add(:url, "must be a valid http(s) URL")
      expect(presenter.errors?).to be(true)
    end
  end

  describe "#error_messages" do
    it "returns full error messages" do
      game_link.errors.add(:url, "must be a valid http(s) URL")
      expect(presenter.error_messages).to include("Url must be a valid http(s) URL")
    end
  end

  describe "#to_model" do
    it "returns the underlying model" do
      expect(presenter.to_model).to eq(game_link)
    end
  end
end
