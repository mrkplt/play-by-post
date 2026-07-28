require "rails_helper"

RSpec.describe "Games", type: :feature do
  let(:gm) { create(:user, :with_profile) }

  before { sign_in_as(gm) }

  describe "dashboard" do
    it "shows empty state when user has no games" do
      expect(page).to have_text("You're not in any games yet")
      expect(page).to have_link("Create a game")
    end

    it "lists games the user belongs to" do
      game = create(:game, name: "The Lost Realm")
      create(:game_member, :game_master, game: game, user: gm)

      visit root_path

      expect(page).to have_text("The Lost Realm")
      expect(page).to have_text("GM")
    end

    it "lists games in alphabetical order" do
      create(:game_member, :game_master, game: create(:game, name: "Zebra Campaign"), user: gm)
      create(:game_member, :game_master, game: create(:game, name: "Alpha Campaign"), user: gm)

      visit root_path

      expect(page.body).to match(/Alpha Campaign.*Zebra Campaign/m)
    end

    it "shows active scene count" do
      game = create(:game)
      create(:game_member, :game_master, game: game, user: gm)
      create(:scene, game: game)
      create(:scene, game: game)
      create(:scene, :resolved, game: game)

      visit root_path

      expect(page).to have_text("2 active scenes")
    end

    it "shows player's character name linked to sheet" do
      game = create(:game)
      create(:game_member, :game_master, game: game, user: gm)
      create(:character, game: game, user: gm, name: "Aldric the Bold")

      visit root_path

      expect(page).to have_link("Aldric the Bold")
    end

    it "shows +N more indicator when player has multiple characters, linking the first" do
      game = create(:game)
      create(:game_member, :game_master, game: game, user: gm)
      create(:character, game: game, user: gm, name: "Aldric the Bold")
      create(:character, game: game, user: gm, name: "Mira Ashveil")
      create(:character, game: game, user: gm, name: "Torven Coldstone")

      visit root_path

      expect(page).to have_link("Aldric the Bold")
      expect(page).to have_text("+2 more")
      expect(page).not_to have_link("Mira Ashveil")
      expect(page).not_to have_link("Torven Coldstone")
    end

    it "does not show +N more indicator when player has only one character" do
      game = create(:game)
      create(:game_member, :game_master, game: game, user: gm)
      create(:character, game: game, user: gm, name: "Aldric the Bold")

      visit root_path

      expect(page).not_to have_text("more")
    end

    it "does not count other players' characters toward the +N more indicator" do
      game = create(:game)
      create(:game_member, :game_master, game: game, user: gm)
      create(:character, game: game, user: gm, name: "Aldric the Bold")
      other_player = create(:user, :with_profile)
      create(:game_member, game: game, user: other_player)
      create(:character, game: game, user: other_player, name: "Mira Ashveil")
      create(:character, game: game, user: other_player, name: "Torven Coldstone")

      visit root_path

      expect(page).to have_link("Aldric the Bold")
      expect(page).not_to have_text("more")
    end

    it "does not count archived characters toward the primary character or +N more" do
      game = create(:game)
      create(:game_member, :game_master, game: game, user: gm)
      create(:character, game: game, user: gm, name: "Active Knight")
      create(:character, :archived, game: game, user: gm, name: "Retired Mage")

      visit root_path

      expect(page).to have_link("Active Knight")
      expect(page).not_to have_text("more")
    end

    it "shows new activity indicator only for the game with new posts" do
      active_game = create(:game, name: "Active Game")
      quiet_game = create(:game, name: "Quiet Game")
      create(:game_member, :game_master, game: active_game, user: gm)
      create(:game_member, :game_master, game: quiet_game, user: gm)
      scene = create(:scene, game: active_game)
      gm.user_profile.update!(last_login_at: 1.hour.ago)
      create(:post, scene: scene, user: gm)

      visit root_path

      expect(page).to have_css("[data-new-activity='true']", count: 1)
    end

    it "shows 'Former' badge for removed players" do
      game = create(:game)
      create(:game_member, game: game, user: gm, role: "player", status: "removed")

      visit root_path

      expect(page).to have_text("Former")
    end

    it "does not show games for banned players" do
      game = create(:game, name: "Hidden Game")
      create(:game_member, game: game, user: gm, role: "player", status: "banned")

      visit root_path

      expect(page).not_to have_text("Hidden Game")
    end

    it "shows new activity indicator when posts exist since last login" do
      game = create(:game)
      create(:game_member, :game_master, game: game, user: gm)
      scene = create(:scene, game: game)
      gm.user_profile.update!(last_login_at: 1.hour.ago)
      create(:post, scene: scene, user: gm)

      visit root_path

      expect(page).to have_css("[data-new-activity='true']")
    end

    it "does not show new activity indicator when no posts since last login" do
      game = create(:game)
      create(:game_member, :game_master, game: game, user: gm)
      scene = create(:scene, game: game)
      gm.user_profile.update!(last_login_at: 1.hour.ago)
      create(:post, scene: scene, user: gm, created_at: 2.hours.ago)

      visit root_path

      expect(page).not_to have_css("[data-new-activity='true']")
    end
  end

  describe "game creation" do
    it "creates a game and lands on the game view" do
      click_on "Create a game"
      fill_in "Name", with: "Shadows of the Rift"
      fill_in "Description (optional)", with: "A dark fantasy adventure"
      click_on "Create game"

      expect(page).to have_text("Shadows of the Rift")
      expect(page).to have_text("A dark fantasy adventure")
    end

    it "makes the creator the GM" do
      click_on "Create a game"
      fill_in "Name", with: "New Campaign"
      click_on "Create game"

      expect(page).to have_link(href: edit_game_path(Game.last))
    end

    it "requires a name" do
      click_on "Create a game"
      click_on "Create game"

      expect(page).to have_text("can't be blank")
    end
  end

  describe "game view" do
    let(:game) { create(:game, name: "Test Game") }

    before { create(:game_member, :game_master, game: game, user: gm) }

    it "shows active scenes" do
      create(:scene, game: game, title: "The Dark Forest")

      visit game_path(game)

      expect(page).to have_text("The Dark Forest")
    end

    it "does not show resolved scenes on the game view" do
      create(:scene, :resolved, game: game, title: "Prologue")

      visit game_path(game)

      expect(page).not_to have_text("Prologue")
    end

    it "shows the character roster" do
      player = create(:user, :with_profile)
      create(:game_member, game: game, user: player)
      create(:character, game: game, user: player, name: "Thornwall")

      visit game_path(game)

      expect(page).to have_text("Thornwall")
    end

    it "shows edit settings link for GM" do
      visit game_path(game)

      expect(page).to have_link(href: edit_game_path(game))
    end

    it "does not show edit settings link for non-GM" do
      player = create(:user, :with_profile)
      create(:game_member, game: game, user: player)

      sign_in_as(player)
      visit game_path(game)

      expect(page).not_to have_link(href: edit_game_path(game))
    end

    it "shows New Scene button for GM" do
      visit game_path(game)

      expect(page).to have_link("New Scene")
    end

    it "does not show New Scene button for players" do
      player = create(:user, :with_profile)
      create(:game_member, game: game, user: player)

      sign_in_as(player)
      visit game_path(game)

      expect(page).not_to have_link("New Scene")
    end

    it "shows All Scenes link" do
      visit game_path(game)

      expect(page).to have_link("All Scenes")
    end

    it "shows Manage Files link for GM" do
      visit game_path(game)

      expect(page).to have_link("Manage Files", href: game_game_files_path(game))
    end

    it "shows View Files link for non-GM players" do
      player = create(:user, :with_profile)
      create(:game_member, game: game, user: player)

      sign_in_as(player)
      visit game_path(game)

      expect(page).to have_link("View Files", href: game_game_files_path(game))
      expect(page).not_to have_link("Manage Files")
    end

    it "removed member can access game files" do
      player = create(:user, :with_profile)
      create(:game_member, game: game, user: player, status: "removed")

      sign_in_as(player)
      visit game_game_files_path(game)

      expect(page).to have_current_path(game_game_files_path(game))
      expect(page).to have_css("h1", text: "Game Files")
      expect(page).to have_text("No files uploaded yet.")
    end

    it "shows parent and children links on active scene cards" do
      parent = create(:scene, :resolved, game: game, title: "The Road")
      active = create(:scene, game: game, title: "The Bridge", parent_scene: parent)
      child = create(:scene, game: game, title: "The Castle", parent_scene: active)

      visit game_path(game)

      expect(page).to have_text("The Bridge")
      expect(page).to have_link("The Road")
      expect(page).to have_link("The Castle")
    end
  end

  describe "game edit" do
    let(:game) { create(:game, name: "Test Campaign", description: "A test game") }

    before { create(:game_member, :game_master, game: game, user: gm) }

    it "GM can access the edit page" do
      visit game_path(game)
      find("a[href='#{edit_game_path(game)}']").click

      expect(page).to have_current_path(edit_game_path(game))
      expect(page).to have_field("Name", with: "Test Campaign")
    end

    it "GM can update game details" do
      visit edit_game_path(game)
      fill_in "Name", with: "Updated Campaign"
      fill_in "Description", with: "An updated description"
      click_on "Save Changes"

      expect(page).to have_current_path(game_path(game))
      expect(page).to have_text("Updated Campaign")
      expect(page).to have_text("An updated description")
    end

    it "GM can access manage players from edit page" do
      visit edit_game_path(game)

      expect(page).to have_link("Manage Players")
    end

    it "GM can toggle character sheet visibility from edit page" do
      expect(game.sheets_hidden?).to be false

      visit edit_game_path(game)
      click_on "Hide Character Sheets"

      expect(page).to have_current_path(game_path(game))
      expect(game.reload.sheets_hidden?).to be true
    end

    it "non-GM cannot access the edit page" do
      player = create(:user, :with_profile)
      create(:game_member, game: game, user: player)

      sign_in_as(player)
      visit edit_game_path(game)

      expect(page).to have_current_path(game_path(game))
    end
  end
end
