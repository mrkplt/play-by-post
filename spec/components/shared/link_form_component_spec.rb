require "rails_helper"

RSpec.describe Shared::LinkFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }
  let(:new_link) { present(game.game_links.new) }
  let(:existing_link) { present(build_stubbed(:game_link, game: game, description: "Map", url: "https://example.com/map")) }

  def present(game_link)
    GameLinkPresenter.new(game_link, policy: instance_double(GameLinkPolicy), game_policy: instance_double(GamePolicy))
  end

  def build_component(game_link:)
    described_class.new(game: game_presenter, game_link: game_link)
  end

  describe "mode derived from the link" do
    it "treats an unpersisted link as a new record" do
      component = build_component(game_link: new_link)
      expect(component.new_record?).to be(true)
      expect(component.submit_label).to eq("Create Link")
    end

    it "treats a persisted link as an edit" do
      component = build_component(game_link: existing_link)
      expect(component.new_record?).to be(false)
      expect(component.submit_label).to eq("Save")
    end
  end

  describe "back_href" do
    it "points a new link's back_href at the links index" do
      component = build_component(game_link: new_link)
      render_inline(component)
      expect(component.back_href).to eq(Rails.application.routes.url_helpers.game_game_links_path(game))
    end

    it "points an edit's back_href at the links index too" do
      component = build_component(game_link: existing_link)
      render_inline(component)
      expect(component.back_href).to eq(Rails.application.routes.url_helpers.game_game_links_path(game))
    end
  end

  describe "form_id" do
    it "gives new and edit forms distinct, stable ids for the external submit button" do
      render_inline(build_component(game_link: new_link))
      expect(page).to have_css("form#new_game_link_form")
    end

    it "scopes the edit form id to the record" do
      render_inline(build_component(game_link: existing_link))
      expect(page).to have_css("form#edit_game_link_#{existing_link.id}_form")
    end
  end

  describe "error surfacing" do
    it "reports no errors on a clean link" do
      expect(build_component(game_link: existing_link).errors?).to be(false)
    end

    it "surfaces validation messages" do
      new_link.valid?
      new_link.errors.add(:url, "must be a valid http(s) URL")
      component = build_component(game_link: new_link)
      expect(component.errors?).to be(true)
      expect(component.error_messages).to include("Url must be a valid http(s) URL")
    end
  end

  describe "rendering" do
    it "renders description and url fields" do
      render_inline(build_component(game_link: new_link))
      expect(page).to have_field("game_link[description]")
      expect(page).to have_field("game_link[url]")
    end
  end
end
