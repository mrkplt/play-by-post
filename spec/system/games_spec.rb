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

      expect(page).to have_link("Manage Players")
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

    it "shows resolved scenes in a separate list" do
      create(:scene, :resolved, game: game, title: "Prologue")

      visit game_path(game)

      expect(page).to have_text("Prologue")
      expect(page).to have_text("Resolved Scenes")
    end

    it "shows the character roster" do
      player = create(:user, :with_profile)
      create(:game_member, game: game, user: player)
      create(:character, game: game, user: player, name: "Thornwall")

      visit game_path(game)

      expect(page).to have_text("Thornwall")
    end

    it "shows manage players link for GM" do
      visit game_path(game)

      expect(page).to have_link("Manage Players")
    end

    it "does not show manage players link for non-GM" do
      player = create(:user, :with_profile)
      create(:game_member, game: game, user: player)

      sign_in_as(player)
      visit game_path(game)

      expect(page).not_to have_link("Manage Players")
    end
  end
end
