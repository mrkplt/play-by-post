require "rails_helper"

RSpec.describe GameMemberPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:member) { build_stubbed(:game_member) }

  subject(:policy) { described_class.new(user, member) }

  before do
    allow(member).to receive(:game).and_return(game)
    allow(member).to receive(:game_master?).and_return(false)
  end

  describe "#update? (GM manages non-GM members)" do
    it "is true when the user is GM and the target member is not a GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      allow(member).to receive(:game_master?).and_return(false)
      expect(policy.update?).to be(true)
    end

    it "is false when the target member is itself a GM (cannot change GM status)" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      allow(member).to receive(:game_master?).and_return(true)
      expect(policy.update?).to be(false)
    end

    it "is false when the user is not GM of the member's game" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(policy.update?).to be(false)
    end
  end
end
