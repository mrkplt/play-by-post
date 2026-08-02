require "rails_helper"

RSpec.describe SceneSummaryPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:scene) { instance_double(Scene) }
  let(:summary) { build_stubbed(:scene_summary) }

  subject(:policy) { described_class.new(user, summary) }

  before do
    allow(summary).to receive(:scene).and_return(scene)
    allow(scene).to receive(:game).and_return(game)
  end

  describe "#create? / #update? / #destroy? (GM only)" do
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
end
