require "rails_helper"

RSpec.describe PagePolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:page) { build_stubbed(:page) }

  subject(:policy) { described_class.new(user, page) }

  before do
    allow(page).to receive(:game).and_return(game)
    # Defaults: not the GM, not an active member, contributions off, not the
    # author. Each example flips only the axis it exercises.
    allow(game).to receive(:game_master?).with(user).and_return(false)
    allow(game).to receive(:active_member?).with(user).and_return(false)
    allow(game).to receive(:player_contributions_enabled?).and_return(false)
    allow(page).to receive(:created_by?).with(user).and_return(false)
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

  describe "#update? / #publish? (GM only, unaffected by player contributions)" do
    it "are true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.update?).to be(true)
      expect(policy.publish?).to be(true)
    end

    it "are false for a contributing active member who authored the page" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      allow(page).to receive(:created_by?).with(user).and_return(true)
      expect(policy.update?).to be(false)
      expect(policy.publish?).to be(false)
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
    it "is true for the GM even for a page they did not author" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.destroy?).to be(true)
    end

    it "is true for a contributing active member who authored the page" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      allow(page).to receive(:created_by?).with(user).and_return(true)
      expect(policy.destroy?).to be(true)
    end

    it "is false for an active member who did not author the page" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.destroy?).to be(false)
    end

    it "is false for the author once contributions are disabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(page).to receive(:created_by?).with(user).and_return(true)
      expect(policy.destroy?).to be(false)
    end
  end

  describe "#show?" do
    context "for a published page (any non-banned member)" do
      before { allow(page).to receive(:draft?).and_return(false) }

      it "is true when the game is viewable by the user" do
        allow(game).to receive(:viewable_by?).with(user).and_return(true)
        expect(policy.show?).to be(true)
      end

      it "is false when the game is not viewable by the user" do
        allow(game).to receive(:viewable_by?).with(user).and_return(false)
        expect(policy.show?).to be(false)
      end
    end

    context "for a draft page (manager only)" do
      before { allow(page).to receive(:draft?).and_return(true) }

      it "is true for the GM" do
        allow(game).to receive(:game_master?).with(user).and_return(true)
        expect(policy.show?).to be(true)
      end

      it "is false for a non-GM even when the game is viewable" do
        allow(game).to receive(:game_master?).with(user).and_return(false)
        allow(game).to receive(:viewable_by?).with(user).and_return(true)
        expect(policy.show?).to be(false)
      end
    end
  end
end
