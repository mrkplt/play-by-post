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

    it "non-GM active player can access the settings page, but not player-management controls" do
      sign_in(player)
      get game_player_management_path(game)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Invite a Player")
      expect(response.body).not_to include("Game Preferences")
    end

    it "non-GM active player sees the Export section" do
      sign_in(player)
      get game_player_management_path(game)
      expect(response.body).to include("Export Game")
    end

    it "removed member can access the settings page" do
      game.member_for(player).update!(status: "removed")
      sign_in(player)
      get game_player_management_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "banned member is redirected with alert" do
      game.member_for(player).update!(status: "banned")
      sign_in(player)
      get game_player_management_path(game)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/do not have access/i)
    end

    it "non-member is redirected with alert" do
      outsider = create(:user, :with_profile)
      sign_in(outsider)
      get game_player_management_path(game)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/do not have access/i)
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

    it "shows a member's character name as their subtitle" do
      player.user_profile.update!(display_name: "Quest Master")
      create(:character, game: game, user: player, name: "Thorin Oakenshield")
      sign_in(gm)
      get game_player_management_path(game)
      expect(response.body).to include("Thorin Oakenshield")
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

    it "shows pending invitations in reverse chronological order" do
      create(:invitation, game: game, email: "older@example.com", invited_by: gm, created_at: 2.days.ago)
      create(:invitation, game: game, email: "newer@example.com", invited_by: gm, created_at: 1.day.ago)
      sign_in(gm)
      get game_player_management_path(game)
      older_pos = response.body.index("older@example.com")
      newer_pos = response.body.index("newer@example.com")
      expect(newer_pos).to be < older_pos
    end

    it "renders the new invitation form" do
      sign_in(gm)
      get game_player_management_path(game)
      expect(response.body).to include("invitation")
    end
  end
end
