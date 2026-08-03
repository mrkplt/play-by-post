require "rails_helper"

RSpec.describe GamePresenter do
  let(:game) { build_stubbed(:game) }
  let(:user) { build_stubbed(:user) }

  subject(:presenter) { described_class.new(game, user) }

  describe "#gm?" do
    it "is true when the viewer runs the game" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(presenter.gm?).to be(true)
    end

    it "is false when the viewer does not run the game" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(presenter.gm?).to be(false)
    end
  end

  describe "#pending_invitations" do
    it "returns the game's pending invitations, newest first" do
      ordered = [ build_stubbed(:invitation), build_stubbed(:invitation) ]
      all_rel = double("all invitations")
      pending_rel = double("pending invitations")
      ordered_rel = double("ordered invitations")
      allow(game).to receive(:invitations).and_return(all_rel)
      allow(all_rel).to receive(:pending).and_return(pending_rel)
      allow(pending_rel).to receive(:order).with(created_at: :desc).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      expect(presenter.pending_invitations).to eq(ordered)
    end
  end

  it "delegates model methods to the game" do
    expect(presenter.name).to eq(game.name)
  end
end
