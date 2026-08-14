require "rails_helper"

RSpec.describe NotebookBoardPresenter do
  let(:game) { build_stubbed(:game) }

  subject(:presenter) { described_class.new(game) }

  describe "#entries_by_status" do
    it "groups the game's notebook entries by status, ordered by created_at" do
      new_entry = build_stubbed(:notebook_entry, game: game, status: "new")
      expand_entry = build_stubbed(:notebook_entry, game: game, status: "expand")
      all_rel = double("all notebook entries")
      ordered_rel = double("ordered notebook entries")
      allow(game).to receive(:notebook_entries).and_return(all_rel)
      allow(all_rel).to receive(:order).with(:created_at).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([ new_entry, expand_entry ])

      grouped = presenter.entries_by_status

      expect(grouped.keys).to contain_exactly("new", "expand")
      expect(grouped.fetch("new").map(&:__getobj__)).to eq([ new_entry ])
      expect(grouped.fetch("expand").map(&:__getobj__)).to eq([ expand_entry ])
    end

    it "wraps each entry in a NotebookEntryPresenter" do
      new_entry = build_stubbed(:notebook_entry, game: game, status: "new")
      all_rel = double("all notebook entries")
      ordered_rel = double("ordered notebook entries")
      allow(game).to receive(:notebook_entries).and_return(all_rel)
      allow(all_rel).to receive(:order).with(:created_at).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([ new_entry ])

      expect(presenter.entries_by_status.fetch("new").first).to be_a(NotebookEntryPresenter)
    end
  end

  describe "#entries_for" do
    it "returns the presenters for a given status" do
      new_entry = build_stubbed(:notebook_entry, game: game, status: "new")
      all_rel = double("all notebook entries")
      ordered_rel = double("ordered notebook entries")
      allow(game).to receive(:notebook_entries).and_return(all_rel)
      allow(all_rel).to receive(:order).with(:created_at).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([ new_entry ])

      expect(presenter.entries_for("new").map(&:__getobj__)).to eq([ new_entry ])
    end

    it "returns an empty array for a status with no entries" do
      all_rel = double("all notebook entries")
      ordered_rel = double("ordered notebook entries")
      allow(game).to receive(:notebook_entries).and_return(all_rel)
      allow(all_rel).to receive(:order).with(:created_at).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([])

      expect(presenter.entries_for("discard")).to eq([])
    end
  end
end
