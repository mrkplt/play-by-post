require "rails_helper"

RSpec.describe GameMembersController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:player_member) { create(:game_member, game: game, user: player) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    player_member
  end

  describe "PATCH /games/:game_id/player_management/game_members/:id" do
    it "GM can update a player status" do
      sign_in(gm)
      patch game_player_management_game_member_path(game, player_member), params: { game_member: { status: "removed" } }
      expect(response).to redirect_to(game_player_management_path(game))
      expect(player_member.reload.status).to eq("removed")
    end

    it "GM cannot change GM status" do
      gm_member = game.game_members.find_by(user: gm)
      sign_in(gm)
      patch game_player_management_game_member_path(game, gm_member), params: { game_member: { status: "removed" } }
      expect(response).to redirect_to(game_player_management_path(game))
      expect(flash[:alert]).to match(/cannot change gm/i)
    end

    it "GM gets alert for invalid status" do
      sign_in(gm)
      patch game_player_management_game_member_path(game, player_member), params: { game_member: { status: "invalid" } }
      expect(response).to redirect_to(game_player_management_path(game))
      expect(flash[:alert]).to match(/invalid status/i)
    end

    it "non-GM is redirected" do
      sign_in(player)
      patch game_player_management_game_member_path(game, player_member), params: { game_member: { status: "removed" } }
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end

    it "unauthenticated user is redirected" do
      patch game_player_management_game_member_path(game, player_member), params: { game_member: { status: "removed" } }
      expect(response).to have_http_status(:redirect)
    end
  end
end
