require "rails_helper"

RSpec.describe GameFilePolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:game_file) { build_stubbed(:game_file) }

  subject(:policy) { described_class.new(user, game_file) }

  before do
    allow(game_file).to receive(:game).and_return(game)
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

  describe "#create? / #destroy? (delegate to #manage?)" do
    it "are true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.create?).to be(true)
      expect(policy.destroy?).to be(true)
    end

    it "are false for a non-GM" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(policy.create?).to be(false)
      expect(policy.destroy?).to be(false)
    end
  end
end
