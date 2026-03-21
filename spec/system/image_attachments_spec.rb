require "rails_helper"

RSpec.describe "Image attachments", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }
  let(:fixture_image) { Rails.root.join("spec/fixtures/files/test_image.png") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:scene_participant, scene: scene, user: gm)
    create(:scene_participant, scene: scene, user: player)
  end

  describe "post images" do
    it "participant can create a post with an image" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      fill_in "Write your post...", with: "Check out this map!"
      attach_file "Image (optional)", fixture_image
      click_on "Post"

      expect(page).to have_text("Check out this map!")
      expect(page).to have_css("img[src*='test_image']")
    end

    it "post without image still works" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      fill_in "Write your post...", with: "Just text, no image."
      click_on "Post"

      expect(page).to have_text("Just text, no image.")
    end

    it "shows the image file input in the composer" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).to have_field("Image (optional)")
    end
  end

  describe "scene images" do
    it "GM can create a scene with an image" do
      sign_in_as(gm)
      visit new_game_scene_path(game)

      fill_in "Title", with: "The Dark Forest"
      attach_file "Scene image (optional)", fixture_image
      click_on "Create Scene"

      expect(page).to have_text("The Dark Forest")
      expect(page).to have_css("img[src*='test_image']")
    end

    it "scene without image still works" do
      sign_in_as(gm)
      visit new_game_scene_path(game)

      fill_in "Title", with: "Plain Scene"
      click_on "Create Scene"

      expect(page).to have_text("Plain Scene")
    end
  end
end
