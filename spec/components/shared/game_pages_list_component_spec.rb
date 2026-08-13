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
    described_class.new(**{ game: game, pages: pages, can_manage: false }.merge(overrides))
  end

  describe "#row_controls" do
    it "gives the GM a row's actions" do
      expect(build_component(can_manage: true).row_controls(pages.first))
        .to be_a(Shared::PageRowActionsComponent)
    end

    it "gives a non-GM no row controls" do
      expect(build_component(can_manage: false).row_controls(pages.first)).to be_nil
    end
  end

  describe "rendering" do
    it "lists each page as a link to its show page" do
      render_inline(build_component)
      expect(page).to have_link("Alpha", href: Rails.application.routes.url_helpers.game_page_path(game, pages.first))
      expect(page).to have_link("Beta")
    end

    it "shows the New Page action only to the GM" do
      render_inline(build_component(can_manage: true))
      expect(page).to have_link("New Page")
    end

    it "shows an inline Edit link per row for the GM" do
      render_inline(build_component(can_manage: true))
      expect(page).to have_link("Edit", href: Rails.application.routes.url_helpers.edit_game_page_path(game, pages.first))
      expect(page.all("a", text: "Edit").size).to eq(pages.size)
    end

    it "shows an inline Delete button per row for the GM" do
      render_inline(build_component(can_manage: true))
      expect(page).to have_button("Delete", count: pages.size)
    end

    it "targets the page's destroy route from each Delete button" do
      render_inline(build_component(can_manage: true))
      form = page.find("form[action='#{Rails.application.routes.url_helpers.game_page_path(game, pages.first)}']")
      expect(form).to have_field("_method", type: :hidden, with: "delete")
    end

    it "guards each Delete with an are-you-sure confirmation" do
      render_inline(build_component(can_manage: true))
      expect(page).to have_css("form[data-turbo-confirm]", count: pages.size)
    end

    it "hides inline Edit and Delete from a non-GM" do
      render_inline(build_component(can_manage: false))
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Delete")
    end

    it "no longer renders the chevron affordance" do
      render_inline(build_component(can_manage: false))
      expect(page).to have_no_text("›")
    end

    it "hides the New Page action from a non-GM" do
      render_inline(build_component(can_manage: false))
      expect(page).to have_no_link("New Page")
    end

    it "shows an empty state when there are no pages" do
      render_inline(build_component(pages: []))
      expect(page).to have_text("No pages yet")
    end
  end
end
