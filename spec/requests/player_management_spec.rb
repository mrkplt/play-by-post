require "rails_helper"

RSpec.describe PlayerManagementController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /games/:game_id/player_management" do
    it "GM can access player management" do
      sign_in(gm)
      get game_player_management_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "non-GM player is redirected with alert" do
      sign_in(player)
      get game_player_management_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end

    it "unauthenticated user is redirected" do
      get game_player_management_path(game)
      expect(response).to have_http_status(:redirect)
    end
  end
end
