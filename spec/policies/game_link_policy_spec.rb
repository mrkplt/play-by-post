require "rails_helper"

RSpec.describe GameLinkPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:game_link) { build_stubbed(:game_link) }

  subject(:policy) { described_class.new(user, game_link) }

  before do
    allow(game_link).to receive(:game).and_return(game)
  end

  describe "#manage? (GM only)" do
    it "is true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.manage?).to be(true)
    end

    it "is false for a non-GM" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(policy.manage?).to be(false)
    end
  end

  describe "#create? / #update? / #destroy? (delegate to #manage?)" do
    it "are true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
    end

    it "are false for a non-GM" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
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
