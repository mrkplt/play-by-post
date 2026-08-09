require "rails_helper"

RSpec.describe Shared::NotebookBoardComponent, type: :component do
  let(:game) { build_stubbed(:game) }

  def entry_in(status, title:)
    build_stubbed(:notebook_entry, game: game, status: status, title: title, slug: "#{status}slug1234567890")
  end

  def build_component(entries_by_status: {})
    described_class.new(game: game, entries_by_status: entries_by_status)
  end

  describe "#visible_statuses" do
    it "does not include discard" do
      expect(build_component.visible_statuses).to eq(%w[new expand done])
    end
  end

  describe "#column_label" do
    Shared::NotebookBoardComponent::COLUMN_LABELS.each do |status, label|
      it "labels #{status.inspect} as #{label.inspect}" do
        expect(build_component.column_label(status)).to eq(label)
      end
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
  end
end
