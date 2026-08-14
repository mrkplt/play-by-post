require "rails_helper"

RSpec.describe Shared::NotebookBoardComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }

  def entry_in(status, title:)
    entry = build_stubbed(:notebook_entry, game: game, status: status, title: title, slug: "#{status}slug1234567890")
    NotebookEntryPresenter.new(entry)
  end

  def board_with(entries_by_status)
    board = NotebookBoardPresenter.new(game)
    allow(board).to receive(:entries_for) { |status| entries_by_status.fetch(status, []) }
    board
  end

  def build_component(entries_by_status: {})
    described_class.new(game: game_presenter, board: board_with(entries_by_status))
  end

  describe "#visible_statuses" do
    it "does not include discard" do
      expect(build_component.visible_statuses).to eq(%w[new expand done])
    end
  end

  describe "#column_id" do
    it "is stable and status-scoped, matching the move turbo_stream target" do
      expect(build_component.column_id("expand")).to eq("notebook_column_expand")
    end
  end

  describe "rendering" do
    it "renders a New Entry action" do
      render_inline(build_component)
      expect(page).to have_link("New Entry")
    end

    %w[new expand done].each do |status|
      it "renders an entry under its #{status} column" do
        entry = entry_in(status, title: "In #{status}")
        render_inline(build_component(entries_by_status: { status => [ entry ] }))

        expect(page).to have_css("#notebook_column_#{status}", text: "In #{status}")
      end
    end

    it "hides discard entries behind a details disclosure, not rendered inline in a visible column" do
      discarded = entry_in("discard", title: "Discarded Idea")
      render_inline(build_component(entries_by_status: { "discard" => [ discarded ] }))

      expect(page).to have_css("details summary", text: "Show discarded")
      expect(page).to have_text("Discarded Idea")
    end

    it "shows a placeholder when there is nothing discarded" do
      render_inline(build_component)
      expect(page).to have_text("Nothing discarded.")
    end

    it "shows a placeholder in a visible lane that has no entries" do
      render_inline(build_component)
      expect(page.find("#notebook_column_new")).to have_text(Shared::NotebookLaneComponent::EMPTY_TEXT)
    end
  end

  describe "row composition" do
    it "links an entry's title to its edit screen, not a show screen" do
      entry = entry_in("new", title: "A wandering merchant")
      render_inline(build_component(entries_by_status: { "new" => [ entry ] }))

      expect(page).to have_link(
        "A wandering merchant",
        href: Rails.application.routes.url_helpers.edit_game_notebook_entry_path(game, entry)
      )
    end

    it "carries the lane picker as a row's only control" do
      entry = entry_in("new", title: "A wandering merchant")
      render_inline(build_component(entries_by_status: { "new" => [ entry ] }))

      expect(page).to have_css("select[name='notebook_entry[status]']")
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Promote")
      expect(page).to have_no_button("Delete")
    end

    it "does not render entry bodies — the board is titles only" do
      entry = entry_in("new", title: "Titled")
      allow(entry).to receive(:body).and_return("A body that must not appear on the board.")
      render_inline(build_component(entries_by_status: { "new" => [ entry ] }))

      expect(page).to have_text("Titled")
      expect(page).to have_no_text("A body that must not appear on the board.")
    end

    it "builds one row per entry in the lane" do
      entries = [
        entry_in("new", title: "First"),
        entry_in("new", title: "Second")
      ]
      render_inline(build_component(entries_by_status: { "new" => entries }))

      within_lane = page.find("#notebook_column_new")
      expect(within_lane).to have_link("First")
      expect(within_lane).to have_link("Second")
      expect(within_lane).to have_css("select[name='notebook_entry[status]']", count: 2)
    end
  end
end
