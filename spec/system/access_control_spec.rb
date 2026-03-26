require "rails_helper"

RSpec.describe "Access control for removed/banned players", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
  end

  describe "removed player" do
    before do
      create(:game_member, :removed, game: game, user: player)
    end

    it "sees game on dashboard with Former badge" do
      sign_in_as(player)
      visit root_path

      expect(page).to have_text(game.name)
      expect(page).to have_text("Former")
    end

    it "can view the game page" do
      sign_in_as(player)
      visit game_path(game)

      expect(page).to have_text(game.name)
    end

    it "can view scenes and posts (read-only)" do
      scene = create(:scene, game: game)
      create(:scene_participant, scene: scene, user: gm)
      create(:scene_participant, scene: scene, user: player)
      create(:post, scene: scene, user: gm, content: "Hello from the GM")

      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).to have_text("Hello from the GM")
    end

    it "cannot post in a scene (server-side enforcement)" do
      scene = create(:scene, game: game)
      create(:scene_participant, scene: scene, user: gm)
      create(:scene_participant, scene: scene, user: player)

      sign_in_as(player)
      visit game_scene_path(game, scene)

      # Composer should be hidden for removed players
      expect(page).not_to have_css("#post_composer")
    end

    it "cannot create a character" do
      sign_in_as(player)
      visit new_game_character_path(game)

      expect(page).to have_current_path(game_path(game))
      expect(page).to have_text("You no longer have write access")
    end

    it "cannot edit a character" do
      character = create(:character, game: game, user: player, name: "Old Character")

      sign_in_as(player)
      visit edit_game_character_path(game, character)

      expect(page).to have_current_path(game_path(game))
      expect(page).to have_text("You no longer have write access")
    end
  end

  describe "banned player" do
    before do
      create(:game_member, :banned, game: game, user: player)
    end

    it "does not see game on dashboard" do
      sign_in_as(player)
      visit root_path

      expect(page).not_to have_text(game.name)
    end

    it "cannot access the game directly" do
      sign_in_as(player)
      visit game_path(game)

      expect(page).to have_current_path(root_path)
      expect(page).to have_text("You do not have access to this game")
    end
  end
end
