require "rails_helper"

RSpec.describe "Posts", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
    create(:scene_participant, scene: scene, user: gm)
    create(:scene_participant, scene: scene, user: player)
  end

  describe "creating posts" do
    before { sign_in_as(player) }

    it "participant can post in a scene" do
      visit game_scene_path(game, scene)
      fill_in "Write your post...", with: "The door creaks open slowly."
      click_on "Post"

      expect(page).to have_text("The door creaks open slowly.")
      expect(page).to have_text(player.display_name)
    end

    it "can mark a post as OOC" do
      visit game_scene_path(game, scene)
      fill_in "Write your post...", with: "Anyone want to reschedule?"
      check "Out of character"
      click_on "Post"

      expect(page).to have_text("OOC")
      expect(page).to have_text("Anyone want to reschedule?")
    end

    it "non-participant cannot post" do
      outsider = create(:user, :with_profile)
      create(:game_member, game: game, user: outsider)
      sign_in_as(outsider)

      visit game_scene_path(game, scene)

      expect(page).not_to have_css("#post_composer")
    end
  end

  describe "editing posts" do
    it "author can edit their post within the edit window" do
      sign_in_as(player)
      visit game_scene_path(game, scene)
      fill_in "Write your post...", with: "Orginal typo here."
      click_on "Post"

      click_on "Edit"
      find("textarea").fill_in with: "Original text here."
      click_on "Save"

      expect(page).to have_text("Original text here.")
      expect(page).not_to have_text("Orginal typo here.")
    end

    it "edit link disappears after the edit window" do
      game.update!(post_edit_window_minutes: 10)
      post = create(:post, scene: scene, user: player, created_at: 11.minutes.ago)
      sign_in_as(player)
      visit game_scene_path(game, scene)

      within("#post_#{post.id}") do
        expect(page).not_to have_link("Edit")
      end
    end

    it "another user cannot edit someone else's post" do
      post = create(:post, scene: scene, user: player)
      sign_in_as(gm)
      visit game_scene_path(game, scene)

      within("#post_#{post.id}") do
        expect(page).not_to have_link("Edit")
      end
    end
  end

  describe "OOC filter" do
    before do
      create(:post, scene: scene, user: player, content: "In character text.")
      create(:post, :ooc, scene: scene, user: player, content: "OOC: brb 5 mins")
    end

    it "shows both IC and OOC posts by default" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      expect(page).to have_text("In character text.")
      expect(page).to have_text("OOC: brb 5 mins")
      expect(page).to have_css('[data-testid="ooc-post"]')
    end

    it "Hide OOC posts menu item hides OOC posts" do
      sign_in_as(player)
      visit game_scene_path(game, scene)

      find("button[title='Scene actions']").click
      click_on "Hide OOC posts"

      expect(page).to have_text("In character text.")
      expect(page).not_to have_css('[data-testid="ooc-post"]', visible: true)
    end
  end
end
