require "rails_helper"

RSpec.describe Shared::GameLinksListComponent, type: :component do
  let(:game_model) { build_stubbed(:game) }
  let(:game) { GamePresenter.new(game_model, policy: instance_double(GamePolicy)) }
  let(:link_models) do
    [
      build_stubbed(:game_link, game: game_model, description: "Map", url: "https://example.com/map"),
      build_stubbed(:game_link, game: game_model, description: "Wiki", url: "https://example.com/wiki")
    ]
  end

  # Each link's Edit/Delete affordance follows its own policy (Fizzy #18), so the
  # presenter is built with a stubbed GameLinkPolicy per row. `link_capabilities`
  # sets update?/destroy? for every link in the list.
  def links(update: false, destroy: false)
    link_models.map do |l|
      GameLinkPresenter.new(
        l, game: game_model, urls: Rails.application.routes.url_helpers,
        link_policy: instance_double(GameLinkPolicy, update?: update, destroy?: destroy)
      )
    end
  end

  def build_component(can_contribute: false, update: false, destroy: false, game_links: nil)
    described_class.new(
      game: game,
      game_links: game_links || links(update: update, destroy: destroy),
      can_contribute: can_contribute
    )
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

    it "shows the New Link action to a contributor" do
      render_inline(build_component(can_contribute: true))
      expect(page).to have_link("New Link")
    end

    it "hides the New Link action from a non-contributor" do
      render_inline(build_component(can_contribute: false))
      expect(page).to have_no_link("New Link")
    end

    it "shows Edit and Delete on a row when the link's policy allows both" do
      render_inline(build_component(update: true, destroy: true))
      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete")
    end

    it "shows only Delete on a row the viewer may delete but not edit (an owner)" do
      render_inline(build_component(update: false, destroy: true))
      expect(page).to have_no_link("Edit")
      expect(page).to have_button("Delete")
    end

    it "shows no row actions when the link's policy allows neither" do
      render_inline(build_component(update: false, destroy: false))
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Delete")
    end

    it "shows an empty state when there are no links" do
      render_inline(build_component(game_links: []))
      expect(page).to have_text("No links yet.")
    end
  end
end
