require "rails_helper"

RSpec.describe Shared::GamePagesListComponent, type: :component do
  let(:game_model) { build_stubbed(:game) }
  let(:game) { GamePresenter.new(game_model, policy: instance_double(GamePolicy)) }
  let(:page_models) do
    [
      build_stubbed(:page, game: game_model, title: "Alpha", slug: "alpha00000000000"),
      build_stubbed(:page, game: game_model, title: "Beta", slug: "beta000000000000")
    ]
  end

  # Each page's Edit/Delete affordance follows its own policy (Fizzy #18), so the
  # presenter is built with a stubbed PagePolicy per row exposing update?/destroy?.
  def pages(update: false, destroy: false)
    page_models.map do |p|
      PagePresenter.new(
        p, game: game_model, urls: Rails.application.routes.url_helpers,
        game_policy: instance_double(GamePolicy),
        page_policy: instance_double(PagePolicy, update?: update, destroy?: destroy)
      )
    end
  end

  def build_component(can_contribute: false, update: false, destroy: false, pages: nil)
    described_class.new(
      game: game,
      pages: pages || self.pages(update: update, destroy: destroy),
      can_contribute: can_contribute
    )
  end

  describe "#row_controls" do
    it "gives a row its actions when the page allows edit or delete" do
      editable_pages = pages(update: true)
      component = build_component(pages: editable_pages)
      expect(component.row_controls(editable_pages.first)).to be_a(Shared::PageRowActionsComponent)
    end

    it "gives a row no controls when the page allows neither" do
      plain_pages = pages(update: false, destroy: false)
      component = build_component(pages: plain_pages)
      expect(component.row_controls(plain_pages.first)).to be_nil
    end
  end

  describe "rendering" do
    it "lists each page as a link to its show page" do
      render_inline(build_component)
      expect(page).to have_link("Alpha", href: Rails.application.routes.url_helpers.game_page_path(game_model, page_models.first))
      expect(page).to have_link("Beta")
    end

    it "shows the New Page action to a contributor" do
      render_inline(build_component(can_contribute: true))
      expect(page).to have_link("New Page")
    end

    it "shows an inline Edit link per row when the page allows editing" do
      render_inline(build_component(update: true))
      expect(page).to have_link("Edit", href: Rails.application.routes.url_helpers.edit_game_page_path(game_model, page_models.first))
      expect(page.all("a", text: "Edit").size).to eq(page_models.size)
    end

    it "shows an inline Delete button per row when the page allows deletion" do
      render_inline(build_component(destroy: true))
      expect(page).to have_button("Delete", count: page_models.size)
    end

    it "shows only Delete on a row the viewer may delete but not edit (an owner)" do
      render_inline(build_component(update: false, destroy: true))
      expect(page).to have_no_link("Edit")
      expect(page).to have_button("Delete", count: page_models.size)
    end

    it "targets the page's destroy route from each Delete button" do
      render_inline(build_component(destroy: true))
      form = page.find("form[action='#{Rails.application.routes.url_helpers.game_page_path(game_model, page_models.first)}']")
      expect(form).to have_field("_method", type: :hidden, with: "delete")
    end

    it "guards each Delete with an are-you-sure confirmation" do
      render_inline(build_component(destroy: true))
      expect(page).to have_css("form[data-turbo-confirm]", count: page_models.size)
    end

    it "hides inline Edit and Delete when the page allows neither" do
      render_inline(build_component(update: false, destroy: false))
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Delete")
    end

    it "hides the New Page action from a non-contributor" do
      render_inline(build_component(can_contribute: false))
      expect(page).to have_no_link("New Page")
    end

    it "shows an empty state when there are no pages" do
      render_inline(build_component(pages: []))
      expect(page).to have_text("No pages yet")
    end
  end
end
