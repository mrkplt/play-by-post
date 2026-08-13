require "rails_helper"

RSpec.describe Shared::NotebookLaneComponent, type: :component do
  let(:game) { build_stubbed(:game) }

  def entry(title:, slug:, status: "new")
    build_stubbed(:notebook_entry, game: game, status: status, title: title, slug: slug)
  end

  def build_component(**overrides)
    described_class.new(**{ game: game, status: "new", entries: [] }.merge(overrides))
  end

  describe ".empty_text_for" do
    it "words the discard lane's emptiness as expected, not as an oversight" do
      expect(described_class.empty_text_for("discard")).to eq(described_class::DISCARD_EMPTY_TEXT)
    end

    it "uses the generic empty text for every other lane" do
      %w[new expand done].each do |status|
        expect(described_class.empty_text_for(status)).to eq(described_class::EMPTY_TEXT)
      end
    end
  end

  describe "#dom_id" do
    it "matches the board column id the move response targets" do
      expect(build_component(status: "expand").dom_id).to eq("notebook_column_expand")
      expect(build_component(status: "expand").dom_id)
        .to eq(Shared::NotebookBoardComponent.column_id("expand"))
    end
  end

  describe "rendering" do
    it "wraps the lane in the id the move response replaces" do
      render_inline(build_component(status: "done"))
      expect(page).to have_css("#notebook_column_done")
    end

    it "lists each entry's title as a link to its edit screen" do
      first = entry(title: "First", slug: "firstslug1234567")
      render_inline(build_component(entries: [ first ]))

      expect(page).to have_link(
        "First",
        href: Rails.application.routes.url_helpers.edit_game_notebook_entry_path(game, first)
      )
    end

    it "carries a lane picker per entry" do
      entries = [ entry(title: "First", slug: "firstslug1234567"), entry(title: "Second", slug: "secondslug123456") ]
      render_inline(build_component(entries: entries))
      expect(page).to have_css("select[name='notebook_entry[status]']", count: 2)
    end

    it "shows the empty placeholder when the lane has no entries" do
      render_inline(build_component)
      expect(page).to have_text(described_class::EMPTY_TEXT)
    end

    it "shows the discard wording when an empty lane is the discard lane" do
      render_inline(build_component(status: "discard"))
      expect(page).to have_text(described_class::DISCARD_EMPTY_TEXT)
    end

    it "does not render entry bodies" do
      with_body = build_stubbed(:notebook_entry, game: game, status: "new", title: "Titled",
                                slug: "bodyslug12345678", body: "Body text stays off the board.")
      render_inline(build_component(entries: [ with_body ]))

      expect(page).to have_text("Titled")
      expect(page).to have_no_text("Body text stays off the board.")
    end
  end
end
