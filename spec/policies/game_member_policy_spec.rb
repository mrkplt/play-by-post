require "rails_helper"

RSpec.describe GameMemberPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:member) { build_stubbed(:game_member) }

  subject(:policy) { described_class.new(user, member) }

  before do
    allow(member).to receive(:game).and_return(game)
  end

  describe "#update? (GM of the member's game)" do
    it "is true when the user is GM of the member's game" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.update?).to be(true)
    end

    it "is false when the user is not GM of the member's game" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(policy.update?).to be(false)
    end
  end
end
