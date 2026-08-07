require "rails_helper"

RSpec.describe Shared::GameLinksListComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:links) do
    [
      build_stubbed(:game_link, game: game, description: "Map", url: "https://example.com/map"),
      build_stubbed(:game_link, game: game, description: "Wiki", url: "https://example.com/wiki")
    ]
  end

  def build_component(**overrides)
    described_class.new(**{ game: game, game_links: links, is_gm: false }.merge(overrides))
  end

  describe "#row_classes" do
    it "gives the first row no divider" do
      expect(build_component.row_classes(0)).to eq(described_class::ROW_BASE)
    end

    it "gives later rows a top divider" do
      expect(build_component.row_classes(1)).to include("border-t")
      expect(build_component.row_classes(1)).to include(described_class::ROW_BASE)
    end
  end

  describe "rendering" do
    it "renders the off-site warning at the top" do
      render_inline(build_component)
      expect(page).to have_text("Warning: Links point off this site.")
    end

    it "lists each link as an external link to its URL in a new tab" do
      render_inline(build_component)
      expect(page).to have_link("Map", href: "https://example.com/map", target: "_blank")
      expect(page).to have_link("Wiki")
      anchor = page.find_link("Map", href: "https://example.com/map")
      expect(anchor[:rel]).to eq("noopener noreferrer")
    end

    it "shows the New Link action only to the GM" do
      render_inline(build_component(is_gm: true))
      expect(page).to have_link("New Link")
    end

    it "hides the New Link action from a non-GM" do
      render_inline(build_component(is_gm: false))
      expect(page).to have_no_link("New Link")
    end

    it "shows Edit and Delete actions only to the GM" do
      render_inline(build_component(is_gm: true))
      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete")
    end

    it "hides Edit and Delete actions from a non-GM" do
      render_inline(build_component(is_gm: false))
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Delete")
    end

    it "shows an empty state when there are no links" do
      render_inline(build_component(game_links: []))
      expect(page).to have_text("No links yet.")
    end
  end
end
