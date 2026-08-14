require "rails_helper"

RSpec.describe Shared::NotebookLaneUpdatesComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }

  def moved_entry(from:, to:)
    entry = build_stubbed(:notebook_entry, game: game, status: from, slug: "movedslug1234567")
    entry.status = to
    allow(entry).to receive(:status_previously_was).and_return(from)
    NotebookEntryPresenter.new(entry)
  end

  def build_component(notebook_entry:)
    described_class.new(game: game_presenter, notebook_entry: notebook_entry)
  end

  describe "#affected_statuses" do
    it "names the source and destination lanes of a move" do
      component = build_component(notebook_entry: moved_entry(from: "new", to: "expand"))
      expect(component.affected_statuses).to eq(%w[new expand])
    end

    it "names a single lane when the entry did not actually change lane" do
      component = build_component(notebook_entry: moved_entry(from: "done", to: "done"))
      expect(component.affected_statuses).to eq(%w[done])
    end

    it "ignores a nil previous status rather than emitting an empty lane id" do
      entry = build_stubbed(:notebook_entry, game: game, status: "new", slug: "freshslug1234567")
      allow(entry).to receive(:status_previously_was).and_return(nil)

      component = build_component(notebook_entry: NotebookEntryPresenter.new(entry))
      expect(component.affected_statuses).to eq(%w[new])
    end
  end

  describe "#replacement_disclosure_for" do
    it "re-renders a disclosure lane expanded, so a GM sees the move they just made" do
      component = build_component(notebook_entry: moved_entry(from: "new", to: "discard"))
      expect(component.replacement_disclosure_for("discard")).to eq(:expanded)
    end

    it "leaves an always-visible lane without a disclosure" do
      component = build_component(notebook_entry: moved_entry(from: "new", to: "expand"))
      expect(component.replacement_disclosure_for("expand")).to eq(:none)
    end
  end

  describe "#lanes" do
    it "builds one lane component per affected status" do
      component = build_component(notebook_entry: moved_entry(from: "new", to: "expand"))
      allow(component).to receive(:entries_in).and_return([])

      expect(component.lanes.map(&:dom_id)).to eq(%w[notebook_column_new notebook_column_expand])
    end
  end
end
