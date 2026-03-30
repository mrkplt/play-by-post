require "rails_helper"

RSpec.describe "Player Management", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    sign_in_as(gm)
  end

  describe "player management page" do
    it "GM can access player management" do
      visit edit_game_path(game)
      click_on "Manage Players"

      expect(page).to have_text(player.display_name)
    end

    it "non-GM cannot access player management" do
      sign_in_as(player)
      visit game_player_management_path(game)

      expect(page).to have_current_path(game_path(game))
    end
  end

  describe "invitations" do
    it "GM can invite a player by email" do
      visit game_player_management_path(game)
      find("input[name='invitation[email]']").fill_in with: "newplayer@example.com"
      click_on "Send Invitation"

      expect(page).to have_text("Invitation sent")
    end

    it "invitation email is sent" do
      visit game_player_management_path(game)
      find("input[name='invitation[email]']").fill_in with: "invited@example.com"
      click_on "Send Invitation"

      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include("invited@example.com")
    end

    it "invited player can accept and join the game" do
      invitation = create(:invitation, game: game, email: "newbie@example.com")

      visit accept_invitation_path(invitation.token)

      expect(page).to have_text(game.name)
      expect(GameMember.exists?(game: game, user: User.find_by(email: "newbie@example.com"))).to be true
    end
  end

  describe "removing players" do
    it "GM can remove a player" do
      visit game_player_management_path(game)

      within("tr[data-member-id='#{player.id}']") do
        click_on "Remove"
      end

      expect(game.member_for(player).reload.status).to eq("removed")
    end

    it "removed player sees the game with Former badge" do
      game.member_for(player).update!(status: "removed")
      sign_in_as(player)
      visit root_path

      expect(page).to have_text("Former")
    end

    it "removed player gets read-only access to scenes" do
      scene = create(:scene, game: game)
      create(:scene_participant, scene: scene, user: player)
      game.member_for(player).update!(status: "removed")

      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).not_to have_css("#post_composer")
    end
  end

  describe "banning players" do
    it "GM can ban a player" do
      visit game_player_management_path(game)

      within("tr[data-member-id='#{player.id}']") do
        click_on "Ban"
      end

      expect(game.member_for(player).reload.status).to eq("banned")
    end

    it "banned player does not see the game on dashboard" do
      game.member_for(player).update!(status: "banned")
      sign_in_as(player)
      visit root_path

      expect(page).not_to have_text(game.name)
    end

    it "banned player cannot access the game" do
      game.member_for(player).update!(status: "banned")
      sign_in_as(player)

      visit game_path(game)

      expect(page).to have_current_path(root_path)
    end

    it "banned player cannot access a scene directly" do
      scene = create(:scene, game: game)
      create(:scene_participant, scene: scene, user: player)
      game.member_for(player).update!(status: "banned")
      sign_in_as(player)

      visit game_scene_path(game, scene)

      expect(page).to have_current_path(root_path)
    end
  end
end
