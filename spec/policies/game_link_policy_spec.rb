require "rails_helper"

RSpec.describe GameLinkPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:game_link) { build_stubbed(:game_link) }

  subject(:policy) { described_class.new(user, game_link) }

  before do
    allow(game_link).to receive(:game).and_return(game)
    # Defaults: not the GM, not an active member, contributions off, not the
    # author. Each example flips only the axis it exercises.
    allow(game).to receive(:game_master?).with(user).and_return(false)
    allow(game).to receive(:active_member?).with(user).and_return(false)
    allow(game).to receive(:player_contributions_enabled?).and_return(false)
    allow(game_link).to receive(:created_by?).with(user).and_return(false)
  end

  describe "#manage? (GM only)" do
    it "is true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.manage?).to be(true)
    end

    it "is false for a non-GM" do
      expect(policy.manage?).to be(false)
    end
  end

  describe "#update? (GM only, unaffected by player contributions)" do
    it "is true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.update?).to be(true)
    end

    it "is false for a contributing active member (players do not edit others' links)" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      allow(game_link).to receive(:created_by?).with(user).and_return(true)
      expect(policy.update?).to be(false)
    end
  end

  describe "#create?" do
    it "is true for the GM regardless of the contributions setting" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.create?).to be(true)
    end

    it "is true for an active member when contributions are enabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.create?).to be(true)
    end

    it "is false for an active member when contributions are disabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      expect(policy.create?).to be(false)
    end

    it "is false for a non-member even when contributions are enabled" do
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.create?).to be(false)
    end
  end

  describe "#destroy?" do
    it "is true for the GM even for a link they did not create" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.destroy?).to be(true)
    end

    it "is true for a contributing active member who created the link" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      allow(game_link).to receive(:created_by?).with(user).and_return(true)
      expect(policy.destroy?).to be(true)
    end

    it "is false for an active member who did not create the link" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.destroy?).to be(false)
    end

    it "is false for the author once contributions are disabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game_link).to receive(:created_by?).with(user).and_return(true)
      expect(policy.destroy?).to be(false)
    end
  end

  describe "#index? (any non-banned member)" do
    it "is true when the game is viewable by the user" do
      allow(game).to receive(:viewable_by?).with(user).and_return(true)
      expect(policy.index?).to be(true)
    end

    it "is false when the game is not viewable by the user" do
      allow(game).to receive(:viewable_by?).with(user).and_return(false)
      expect(policy.index?).to be(false)
    end
  end
end
