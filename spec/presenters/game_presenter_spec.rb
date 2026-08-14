require "rails_helper"

RSpec.describe GamePresenter do
  let(:game) { build_stubbed(:game) }
  let(:user) { build_stubbed(:user) }
  let(:policy) { instance_double(GamePolicy, manage?: true) }

  subject(:presenter) { described_class.new(game, policy: policy) }

  describe "#can_manage?" do
    it "is true when the injected policy allows management" do
      allow(policy).to receive(:manage?).and_return(true)
      expect(presenter.can_manage?).to be(true)
    end

    it "is false when the injected policy disallows management" do
      allow(policy).to receive(:manage?).and_return(false)
      expect(presenter.can_manage?).to be(false)
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

  describe "#notebook_entries" do
    it "returns the game's notebook entries grouped by status, ordered by created_at" do
      new_entry = build_stubbed(:notebook_entry, status: "new")
      expand_entry = build_stubbed(:notebook_entry, status: "expand")
      all_rel = double("all notebook entries")
      ordered_rel = double("ordered notebook entries")
      allow(game).to receive(:notebook_entries).and_return(all_rel)
      allow(all_rel).to receive(:order).with(:created_at).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([ new_entry, expand_entry ])

      expect(presenter.notebook_entries).to eq(
        "new" => [ new_entry ],
        "expand" => [ expand_entry ]
      )
    end
  end

  it "delegates model methods to the game" do
    expect(presenter.name).to eq(game.name)
  end
end
