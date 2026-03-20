require "rails_helper"

RSpec.describe "Scenes", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "scene creation" do
    before { sign_in_as(gm) }

    it "creates a scene from the game view" do
      visit game_path(game)
      click_on "New Scene"

      fill_in "Title", with: "The Tavern Encounter"
      fill_in "Description", with: "A dimly lit tavern at the edge of town."
      click_on "Create Scene"

      expect(page).to have_text("The Tavern Encounter")
      expect(page).to have_text("A dimly lit tavern at the edge of town.")
    end

    it "includes the GM as a participant automatically" do
      visit game_path(game)
      click_on "New Scene"
      fill_in "Title", with: "GM Solo Scene"
      click_on "Create Scene"

      expect(page).to have_text(gm.display_name)
    end

    it "allows selecting characters as participants" do
      character = create(:character, game: game, user: player, name: "Seraphina Vex")
      visit game_path(game)
      click_on "New Scene"
      fill_in "Title", with: "Group Scene"
      check character.name
      click_on "Create Scene"

      expect(page).to have_text(character.name)
    end

    it "can create a private scene" do
      visit game_path(game)
      click_on "New Scene"
      fill_in "Title", with: "Secret Scene"
      check "Private scene"
      click_on "Create Scene"

      expect(page).to have_text("Private")
    end

    it "requires a title" do
      visit game_path(game)
      click_on "New Scene"
      click_on "Create Scene"

      expect(page).to have_text("can't be blank").or have_text("Title")
    end
  end

  describe "quick scene" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
      create(:scene_participant, scene: scene, user: player)
      sign_in_as(gm)
    end

    it "creates a quick scene inheriting the parent" do
      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click
      click_on "Quick Scene"

      fill_in "Title", with: "Continuation"
      click_on "Create Quick Scene"

      expect(page).to have_text("Continuation")
      expect(page).to have_text("Continues from #{scene.title}")
    end
  end

  describe "scene view" do
    let(:scene) { create(:scene, game: game, title: "The Bridge") }

    before do
      create(:scene_participant, scene: scene, user: gm)
      create(:scene_participant, scene: scene, user: player)
    end

    it "shows scene title and participants" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).to have_text("The Bridge")
      expect(page).to have_text(player.display_name)
      expect(page).to have_text(gm.display_name)
    end

    it "shows private badge for private scenes" do
      scene.update!(private: true)
      sign_in_as(gm)
      visit game_scene_path(game, scene)

      expect(page).to have_text("Private")
    end

    it "shows parent scene link when scene has a parent" do
      parent = create(:scene, game: game, title: "The Road")
      scene.update!(parent_scene: parent)
      sign_in_as(gm)
      visit game_scene_path(game, scene)

      expect(page).to have_text("Continues from")
      expect(page).to have_link("The Road")
    end

    it "hides private scene from non-participants" do
      scene.update!(private: true)
      outsider = create(:user, :with_profile)
      create(:game_member, game: game, user: outsider)
      sign_in_as(outsider)

      visit game_scene_path(game, scene)

      expect(page).to have_current_path(game_path(game))
    end
  end

  describe "scene resolution" do
    let(:scene) { create(:scene, game: game, title: "The Final Battle") }

    before do
      create(:scene_participant, scene: scene, user: gm)
      sign_in_as(gm)
    end

    it "GM can resolve a scene with outcome text" do
      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click
      click_on "End Scene"
      fill_in "Outcome (optional)", with: "The party defeated the dragon."
      click_on "Confirm — End Scene"

      expect(page).to have_text("Resolved")
      expect(page).to have_text("The party defeated the dragon.")
    end

    it "resolved scene no longer shows the composer" do
      scene.update!(resolved_at: Time.current, resolution: "Done.")
      visit game_scene_path(game, scene)

      expect(page).not_to have_css("#post_composer")
    end

    it "player cannot see the End Scene button" do
      create(:scene_participant, scene: scene, user: player)
      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).not_to have_button("End Scene")
    end
  end

  describe "notification mute" do
    let(:scene) { create(:scene, game: game) }

    before do
      create(:scene_participant, scene: scene, user: gm)
      sign_in_as(gm)
    end

    it "can mute and unmute notifications for a scene" do
      visit game_scene_path(game, scene)
      find("button[title='Scene actions']").click
      click_on "Mute notifications"

      expect(page).to have_text("Notifications muted")

      find("button[title='Scene actions']").click
      click_on "Unmute notifications"

      expect(page).to have_text("Notifications enabled")
    end
  end
end
