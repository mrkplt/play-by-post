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

  describe "#lanes" do
    # Each lane must be filled from its OWN status: passing anything else here
    # renders both lanes with the same entries.
    it "fills each lane with the entries of that lane" do
      entry = moved_entry(from: "new", to: "expand")
      component = build_component(notebook_entry: entry)
      board = instance_double(NotebookBoardPresenter)
      allow(game_presenter).to receive(:notebook_board).and_return(board)
      allow(board).to receive(:entries_for).with("new").and_return([])
      allow(board).to receive(:entries_for).with("expand").and_return([ entry ])

      expect(component.lanes.map { |lane| lane.entries.map(&:title) })
        .to eq([ [], [ entry.title ] ])
    end

    it "builds one lane component per affected status" do
      component = build_component(notebook_entry: moved_entry(from: "new", to: "expand"))
      allow(component).to receive(:entries_in).and_return([])

      expect(component.lanes.map(&:dom_id)).to eq(%w[notebook_column_new notebook_column_expand])
    end

    # Discarding something is a request to stop seeing it. A replaced discard
    # lane comes back shut, the way it presents everywhere else.
    it "leaves the discard lane collapsed when an entry is moved into it" do
      component = build_component(notebook_entry: moved_entry(from: "new", to: "discard"))
      allow(component).to receive(:entries_in).and_return([])

      discard = component.lanes.find { |lane| lane.dom_id == "notebook_column_discard" }
      expect(discard.disclosure).to eq(:collapsed)
    end

    it "leaves an always-visible lane without a disclosure" do
      component = build_component(notebook_entry: moved_entry(from: "new", to: "expand"))
      allow(component).to receive(:entries_in).and_return([])

      expanded = component.lanes.find { |lane| lane.dom_id == "notebook_column_expand" }
      expect(expanded.disclosure).to eq(:none)
    end

    # The lanes render inside <template> elements of a Turbo Stream, which
    # Capybara does not treat as live DOM — assert on the markup itself.
    it "renders the discard lane shut, so the bin does not spring open" do
      component = build_component(notebook_entry: moved_entry(from: "new", to: "discard"))
      allow(component).to receive(:entries_in).and_return([])
      markup = render_inline(component).to_html

      expect(markup).to include(%(<details id="notebook_column_discard" class="mt-1">))
      expect(markup).not_to match(/<details[^>]*\bopen\b/)
    end
  end
end
