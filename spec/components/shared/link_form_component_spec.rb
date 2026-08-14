require "rails_helper"

RSpec.describe Shared::LinkFormComponent, type: :component do
  let(:game_model) { build_stubbed(:game) }
  let(:game) { GamePresenter.new(game_model, policy: instance_double(GamePolicy)) }
  let(:new_link_model) { game_model.game_links.new }
  let(:existing_link_model) { build_stubbed(:game_link, game: game_model, description: "Map", url: "https://example.com/map") }
  let(:urls) { Rails.application.routes.url_helpers }

  def presenter_for(model)
    GameLinkPresenter.new(model, game: game_model, urls: urls)
  end

  def build_component(game_link:)
    described_class.new(game: game, game_link: presenter_for(game_link))
  end

  describe "mode derived from the link" do
    it "treats an unpersisted link as a new record" do
      component = build_component(game_link: new_link_model)
      expect(component.new_record?).to be(true)
      expect(component.submit_label).to eq("Create Link")
    end

    it "treats a persisted link as an edit" do
      component = build_component(game_link: existing_link_model)
      expect(component.new_record?).to be(false)
      expect(component.submit_label).to eq("Save")
    end
  end

  describe "back_href" do
    it "points a new link's back_href at the links index" do
      component = build_component(game_link: new_link_model)
      render_inline(component)
      expect(component.back_href).to eq(Rails.application.routes.url_helpers.game_game_links_path(game_model))
    end

    it "points an edit's back_href at the links index too" do
      component = build_component(game_link: existing_link_model)
      render_inline(component)
      expect(component.back_href).to eq(Rails.application.routes.url_helpers.game_game_links_path(game_model))
    end
  end

  describe "form_id" do
    it "gives new and edit forms distinct, stable ids for the external submit button" do
      render_inline(build_component(game_link: new_link_model))
      expect(page).to have_css("form#new_game_link_form")
    end

    it "scopes the edit form id to the record" do
      render_inline(build_component(game_link: existing_link_model))
      expect(page).to have_css("form#edit_game_link_#{existing_link_model.id}_form")
    end
  end

  describe "error surfacing" do
    it "reports no errors on a clean link" do
      expect(build_component(game_link: existing_link_model).errors?).to be(false)
    end

    it "surfaces validation messages" do
      new_link_model.valid?
      new_link_model.errors.add(:url, "must be a valid http(s) URL")
      component = build_component(game_link: new_link_model)
      expect(component.errors?).to be(true)
      expect(component.error_messages).to include("Url must be a valid http(s) URL")
    end
  end

  describe "rendering" do
    it "renders description and url fields" do
      render_inline(build_component(game_link: new_link_model))
      expect(page).to have_field("game_link[description]")
      expect(page).to have_field("game_link[url]")
    end
  end
end
