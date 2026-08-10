require "rails_helper"

RSpec.describe GameLinksController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:removed_player) { create(:user, :with_profile) }
  let(:banned_player) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:game_member, :removed, game: game, user: removed_player)
    create(:game_member, :banned, game: game, user: banned_player)
  end

  describe "GET index" do
    let!(:link) { create(:game_link, game: game, description: "Map", url: "https://example.com/map") }

    it "renders the links for an active member" do
      sign_in(player)
      get game_game_links_path(game)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Map")
    end

    it "is visible to a removed member" do
      sign_in(removed_player)
      get game_game_links_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "is denied to a banned member" do
      sign_in(banned_player)
      get game_game_links_path(game)
      expect(response).to redirect_to(root_path)
    end

    it "is denied to a non-member" do
      sign_in(outsider)
      get game_game_links_path(game)
      expect(response).to redirect_to(root_path)
    end

    it "redirects an unauthenticated visitor" do
      get game_game_links_path(game)
      expect(response).to have_http_status(:redirect)
    end

    it "renders the universal header nav affordances" do
      sign_in(player)
      get game_game_links_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Links")
    end
  end

  describe "GET new" do
    it "is available to the GM" do
      sign_in(gm)
      get new_game_game_link_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "is denied to an active player" do
      sign_in(player)
      get new_game_game_link_path(game)
      expect(response).to redirect_to(game_game_links_path(game))
    end

    it "renders the universal header nav affordances" do
      sign_in(gm)
      get new_game_game_link_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Links")
    end

    it "renders visible text on the primary and cancel page-action buttons" do
      sign_in(gm)
      get new_game_game_link_path(game)
      expect(response.body).to include(">Create Link<")
      expect(response.body).to include(">Cancel<")
    end
  end

  describe "POST create" do
    it "creates a link and redirects to the links index" do
      sign_in(gm)
      expect {
        post game_game_links_path(game), params: { game_link: { description: "Wiki", url: "https://example.com/wiki" } }
      }.to change(GameLink, :count).by(1)

      expect(GameLink.last.description).to eq("Wiki")
      expect(GameLink.last.url).to eq("https://example.com/wiki")
      expect(response).to redirect_to(game_game_links_path(game))
    end

    it "re-renders on validation failure" do
      sign_in(gm)
      expect {
        post game_game_links_path(game), params: { game_link: { description: "", url: "javascript:alert(1)" } }
      }.not_to change(GameLink, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not let an active player create a link" do
      sign_in(player)
      expect {
        post game_game_links_path(game), params: { game_link: { description: "Sneaky", url: "https://example.com/x" } }
      }.not_to change(GameLink, :count)
    end
  end

  describe "GET edit / PATCH update" do
    let!(:link) { create(:game_link, game: game, description: "Original", url: "https://example.com/original") }

    it "lets the GM edit and update" do
      sign_in(gm)
      get edit_game_game_link_path(game, link)
      expect(response).to have_http_status(:ok)

      patch game_game_link_path(game, link), params: { game_link: { description: "Updated", url: "https://example.com/updated" } }
      expect(response).to redirect_to(game_game_links_path(game))
      expect(link.reload.description).to eq("Updated")
      expect(link.reload.url).to eq("https://example.com/updated")
    end

    it "rejects an invalid URL on update" do
      sign_in(gm)
      patch game_game_link_path(game, link), params: { game_link: { url: "javascript:alert(1)" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(link.reload.url).to eq("https://example.com/original")
    end

    it "denies a player" do
      sign_in(player)
      patch game_game_link_path(game, link), params: { game_link: { description: "Hacked" } }
      expect(link.reload.description).to eq("Original")
    end

    it "renders the universal header nav affordances" do
      sign_in(gm)
      get edit_game_game_link_path(game, link)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Links")
    end

    it "renders visible text on the primary and cancel page-action buttons" do
      sign_in(gm)
      get edit_game_game_link_path(game, link)
      expect(response.body).to include(">Save<")
      expect(response.body).to include(">Cancel<")
    end
  end

  describe "DELETE destroy" do
    let!(:link) { create(:game_link, game: game) }

    it "lets the GM delete a link" do
      sign_in(gm)
      expect {
        delete game_game_link_path(game, link)
      }.to change(GameLink, :count).by(-1)
      expect(response).to redirect_to(game_game_links_path(game))
    end

    it "denies a player" do
      sign_in(player)
      expect {
        delete game_game_link_path(game, link)
      }.not_to change(GameLink, :count)
    end
  end
end
