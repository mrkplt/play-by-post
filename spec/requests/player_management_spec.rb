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

    it "shows player email prefix when user has no display name" do
      player_no_name = create(:user)
      create(:game_member, game: game, user: player_no_name)
      sign_in(gm)
      get game_player_management_path(game)
      expect(response.body).to include(player_no_name.email.split("@").first)
    end

    it "shows player display name when set" do
      player.user_profile.update!(display_name: "Quest Master")
      sign_in(gm)
      get game_player_management_path(game)
      expect(response.body).to include("Quest Master")
    end

    it "shows pending invitation email" do
      create(:invitation, game: game, email: "invited@example.com", invited_by: gm)
      sign_in(gm)
      get game_player_management_path(game)
      expect(response.body).to include("invited@example.com")
    end

    it "does not show accepted invitation in pending list" do
      create(:invitation, :accepted, game: game, email: "accepted@example.com", invited_by: gm)
      sign_in(gm)
      get game_player_management_path(game)
      expect(response.body).not_to include("accepted@example.com")
    end

    it "does not show banned members in the members list" do
      banned_user = create(:user, :with_profile)
      banned_user.user_profile.update!(display_name: "Banned Person")
      create(:game_member, :banned, game: game, user: banned_user)
      sign_in(gm)
      get game_player_management_path(game)
      expect(response.body).not_to include("Banned Person")
    end
  end
end
