require "rails_helper"

RSpec.describe "Characters", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "character creation" do
    it "player can create their own character" do
      sign_in_as(player)
      visit game_path(game)
      click_on "New Character"

      fill_in "Name", with: "Sable Nightwhisper"
      fill_in "Sheet (optional)", with: "Race: Half-Elf\nClass: Rogue"
      click_on "Create Character"

      expect(page).to have_text("Sable Nightwhisper")
      expect(page).to have_text("Race: Half-Elf")
    end

    it "GM can create a character on behalf of a player" do
      sign_in_as(gm)
      visit game_path(game)
      click_on "New Character"

      fill_in "Name", with: "NPC Guard"
      find("select[name='character[user_id]']").select(player.display_name)
      click_on "Create Character"

      expect(page).to have_text("NPC Guard")
    end

    it "requires a name" do
      sign_in_as(player)
      visit new_game_character_path(game)
      click_on "Create Character"

      expect(page).to have_text("can't be blank")
    end
  end

  describe "character sheet" do
    let!(:character) { create(:character, game: game, user: player, name: "Thornwall", content: "STR 18\nDEX 10") }

    it "player can view their own character sheet" do
      sign_in_as(player)
      visit game_character_path(game, character)

      expect(page).to have_text("Thornwall")
      expect(page).to have_text("STR 18")
    end

    it "other participants can view character sheets" do
      sign_in_as(gm)
      visit game_character_path(game, character)

      expect(page).to have_text("Thornwall")
    end

    it "shows version history with an entry for the initial save" do
      sign_in_as(player)
      visit game_character_path(game, character)

      find("details").click
      expect(page).to have_text("Version History")
      expect(page).to have_text(player.display_name)
    end
  end

  describe "character editing" do
    let!(:character) { create(:character, game: game, user: player, name: "Vesper") }

    it "player can edit their own character" do
      sign_in_as(player)
      visit edit_game_character_path(game, character)

      fill_in "Sheet", with: "WIS 18\nCHA 14"
      click_on "Save"

      expect(page).to have_text("WIS 18")
    end

    it "GM can edit any character" do
      sign_in_as(gm)
      visit edit_game_character_path(game, character)

      fill_in "Sheet", with: "Updated by GM"
      click_on "Save"

      expect(page).to have_text("Updated by GM")
    end

    it "player cannot edit another player's character" do
      other_player = create(:user, :with_profile)
      create(:game_member, game: game, user: other_player)
      sign_in_as(other_player)

      visit edit_game_character_path(game, character)

      expect(page).to have_current_path(game_character_path(game, character))
    end
  end

  describe "character visibility" do
    let(:other_player) { create(:user, :with_profile) }

    before { create(:game_member, game: game, user: other_player) }

    it "hidden characters are not visible to other players" do
      create(:character, :hidden, game: game, user: player, name: "Secret Character")

      sign_in_as(other_player)
      visit game_path(game)

      expect(page).not_to have_text("Secret Character")
    end

    it "hidden characters are visible to their owner" do
      create(:character, :hidden, game: game, user: player, name: "Secret Character")

      sign_in_as(player)
      visit game_path(game)

      expect(page).to have_text("Secret Character")
    end

    it "GM can always see hidden characters" do
      create(:character, :hidden, game: game, user: player, name: "Secret Character")

      sign_in_as(gm)
      visit game_path(game)

      expect(page).to have_text("Secret Character")
    end

    it "player can hide their character sheet and other players cannot access it" do
      character = create(:character, game: game, user: player, name: "Sable")

      # Player checks the hide checkbox
      sign_in_as(player)
      visit edit_game_character_path(game, character)
      check "Hide from other players"
      click_on "Save"

      expect(page).to have_text("Character updated")

      # Other player cannot see it on the roster
      sign_in_as(other_player)
      visit game_path(game)
      expect(page).not_to have_text("Sable")

      # Other player cannot access the sheet URL directly
      visit game_character_path(game, character)
      expect(page).to have_current_path(game_path(game))
      expect(page).to have_text("hidden")
    end

    it "hidden character sheet is still accessible by the GM" do
      character = create(:character, :hidden, game: game, user: player, name: "Sable")

      sign_in_as(gm)
      visit game_character_path(game, character)

      expect(page).to have_text("Sable")
    end
  end
end
