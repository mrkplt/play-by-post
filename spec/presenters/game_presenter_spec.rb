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

  describe "#pages" do
    it "returns the game's pages ordered by title" do
      ordered = [ build_stubbed(:page), build_stubbed(:page) ]
      all_rel = double("all pages")
      ordered_rel = double("ordered pages")
      allow(game).to receive(:pages).and_return(all_rel)
      allow(all_rel).to receive(:order).with(:title).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(ordered)

      expect(presenter.pages).to eq(ordered)
    end
  end

  describe "#description_display" do
    it "returns the description when present" do
      allow(game).to receive(:description).and_return("A grim frontier saga")
      expect(presenter.description_display).to eq("A grim frontier saga")
    end

    it "returns a placeholder when the description is blank" do
      allow(game).to receive(:description).and_return("")
      expect(presenter.description_display).to eq("No description yet.")
    end

    it "returns a placeholder when the description is nil" do
      allow(game).to receive(:description).and_return(nil)
      expect(presenter.description_display).to eq("No description yet.")
    end
  end

  it "delegates model methods to the game" do
    expect(presenter.name).to eq(game.name)
  end
end
