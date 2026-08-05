require "rails_helper"

RSpec.describe Shared::GamePagesListComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:pages) do
    [
      build_stubbed(:page, game: game, title: "Alpha", slug: "alpha00000000000"),
      build_stubbed(:page, game: game, title: "Beta", slug: "beta000000000000")
    ]
  end

  def build_component(**overrides)
    described_class.new(**{ game: game, pages: pages, is_gm: false }.merge(overrides))
  end

  describe "#row_classes" do
    it "gives the first row no divider" do
      expect(build_component.row_classes(0)).to eq(described_class::ROW_BASE)
    end

    it "gives later rows a top divider" do
      expect(build_component.row_classes(1)).to include("border-t")
    end
  end

  describe "rendering" do
    it "lists each page as a link to its show page" do
      render_inline(build_component)
      expect(page).to have_link("Alpha", href: Rails.application.routes.url_helpers.game_page_path(game, pages.first))
      expect(page).to have_link("Beta")
    end

    it "shows the New Page action only to the GM" do
      render_inline(build_component(is_gm: true))
      expect(page).to have_link("New Page")
    end

    it "hides the New Page action from a non-GM" do
      render_inline(build_component(is_gm: false))
      expect(page).to have_no_link("New Page")
    end

    it "shows an empty state when there are no pages" do
      render_inline(build_component(pages: []))
      expect(page).to have_text("No pages yet")
    end
  end
end
