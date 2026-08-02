require "rails_helper"

RSpec.describe GamePolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { build_stubbed(:game) }

  subject(:policy) { described_class.new(user, game) }

  def stub_game(gm: false, viewable: false)
    allow(game).to receive(:game_master?).with(user).and_return(gm)
    allow(game).to receive(:viewable_by?).with(user).and_return(viewable)
  end

  describe "#show? / #manage_players? / #export? (any viewer)" do
    it "are true when the game is viewable" do
      stub_game(viewable: true)
      expect(policy.show?).to be(true)
      expect(policy.manage_players?).to be(true)
      expect(policy.export?).to be(true)
    end

    it "are false when the game is not viewable" do
      stub_game(viewable: false)
      expect(policy.show?).to be(false)
      expect(policy.manage_players?).to be(false)
      expect(policy.export?).to be(false)
    end
  end

  describe "#create? / #new? (any authenticated user)" do
    it "is always true" do
      expect(policy.create?).to be(true)
      expect(policy.new?).to be(true)
    end
  end

  describe "#update? / #edit? (GM only)" do
    it "is true for the GM" do
      stub_game(gm: true)
      expect(policy.update?).to be(true)
      expect(policy.edit?).to be(true)
    end

    it "is false for a non-GM" do
      stub_game(gm: false)
      expect(policy.update?).to be(false)
      expect(policy.edit?).to be(false)
    end
  end
end
