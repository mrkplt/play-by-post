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
    it "GM can access player management via the game header gear" do
      visit game_path(game)
      find("a[aria-label='Game settings']").click

      expect(page).to have_text(player.display_name)
    end

    it "non-GM sees the settings page via the gear, without player-management controls" do
      sign_in_as(player)
      visit game_path(game)
      find("a[aria-label='Game settings']").click

      expect(page).to have_current_path(game_player_management_path(game))
      expect(page).not_to have_text("Invite a Player")
      expect(page).to have_button("Export Game")
    end

    it "banned member cannot access the settings page" do
      game.member_for(player).update!(status: "banned")
      sign_in_as(player)
      visit game_player_management_path(game)

      expect(page).to have_current_path(root_path)
    end
  end

  describe "invitations" do
    it "GM can invite a player by email" do
      visit game_player_management_path(game)
      find("input[name='invitation[email]']").fill_in with: "newplayer@example.com"
      click_on "Invite"

      expect(page).to have_text("Invitation sent")
    end

    it "invitation email is sent" do
      visit game_player_management_path(game)
      find("input[name='invitation[email]']").fill_in with: "invited@example.com"
      click_on "Invite"

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

      within(:xpath, "//div[contains(@class,'items-center')][.//span[normalize-space()='#{player.display_name}']]") do
        click_on "Remove"
      end

      expect(game.member_for(player).reload.status).to eq("removed")
    end

    it "removed player sees the game as not currently active on the dashboard" do
      game.member_for(player).update!(status: "removed")
      sign_in_as(player)
      visit root_path

      expect(page).to have_text("Not currently active")
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

  describe "pending invitations" do
    it "shows pending invitations list" do
      create(:invitation, game: game, email: "pending@example.com")

      visit game_player_management_path(game)

      expect(page).to have_text(/pending invitations/i)
      expect(page).to have_text("pending@example.com")
    end

    it "GM can cancel a pending invitation" do
      invitation = create(:invitation, game: game, email: "todelete@example.com")

      visit game_player_management_path(game)

      within(:xpath, "//div[contains(@class,'items-center')][.//span[normalize-space()='todelete@example.com']]") do
        click_on "Cancel"
      end

      expect(page).not_to have_text("todelete@example.com")
      expect(page).to have_text("Invitation cancelled")
      expect(Invitation.exists?(invitation.id)).to be false
    end
  end

  describe "player status" do
    it "removed players remain listed but banned players do not" do
      removed = create(:user, :with_profile)
      create(:game_member, :removed, game: game, user: removed)
      game.member_for(player).update!(status: "banned")

      visit game_player_management_path(game)

      expect(page).to have_text(removed.display_name)
      expect(page).not_to have_text(player.display_name)
    end
  end

  describe "banning players" do
    it "GM can ban a player" do
      visit game_player_management_path(game)

      within(:xpath, "//div[contains(@class,'items-center')][.//span[normalize-space()='#{player.display_name}']]") do
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
