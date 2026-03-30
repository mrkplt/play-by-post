require "rails_helper"

RSpec.describe "Games", type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /games/:id/edit" do
    it "GM can access the edit form" do
      sign_in(gm)
      get edit_game_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "player is redirected with alert" do
      sign_in(player)
      get edit_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end

    it "unauthenticated user is redirected" do
      get edit_game_path(game)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /games/:id" do
    it "GM can update the game" do
      sign_in(gm)
      patch game_path(game), params: { game: { name: "Updated Name" } }
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.name).to eq("Updated Name")
    end

    it "GM can update the description" do
      sign_in(gm)
      patch game_path(game), params: { game: { description: "New desc" } }
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.description).to eq("New desc")
    end

    it "renders edit on invalid params" do
      sign_in(gm)
      patch game_path(game), params: { game: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "player cannot update the game" do
      sign_in(player)
      patch game_path(game), params: { game: { name: "Hacked" } }
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.name).not_to eq("Hacked")
    end

    it "unauthenticated user is redirected" do
      patch game_path(game), params: { game: { name: "Hacked" } }
      expect(response).to have_http_status(:redirect)
    end
  end
end
