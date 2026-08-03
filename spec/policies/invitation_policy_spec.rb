require "rails_helper"

RSpec.describe InvitationPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:invitation) { build_stubbed(:invitation) }

  subject(:policy) { described_class.new(user, invitation) }

  before do
    allow(invitation).to receive(:game).and_return(game)
  end

  describe "#create? / #destroy? (GM of the invitation's game)" do
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
