require "rails_helper"

RSpec.describe "Game pages", type: :feature do
  let(:game) { create(:game, name: "Sunken Archive") }
  let(:gm) { create(:user, :with_profile) }

  before { create(:game_member, :game_master, game: game, user: gm) }

  describe "editing a page" do
    it "saves and confirms without leaving the editor" do
      subject_page = create(:page, game: game, title: "House Rules")
      sign_in_as(gm)
      visit edit_game_page_path(game, subject_page)

      fill_in "page[title]", with: "House Rules (revised)"
      click_on "Save"

      expect(page).to have_text("Page updated.")
      expect(page).to have_current_path(edit_game_page_path(game, subject_page))
      expect(page).to have_field("page[title]", with: "House Rules (revised)")
      expect(subject_page.reload.title).to eq("House Rules (revised)")
    end

    it "saves repeatedly without leaving the editor" do
      subject_page = create(:page, game: game, title: "House Rules")
      sign_in_as(gm)
      visit edit_game_page_path(game, subject_page)

      fill_in "page[title]", with: "First save"
      click_on "Save"
      expect(page).to have_text("Page updated.")

      fill_in "page[title]", with: "Second save"
      click_on "Save"

      # Wait on the re-rendered form before reading the record: click_on
      # returns as soon as the request is issued, so asserting on the database
      # first races the response.
      expect(page).to have_field("page[title]", with: "Second save")
      expect(page).to have_current_path(edit_game_page_path(game, subject_page))
      expect(subject_page.reload.title).to eq("Second save")
    end

    it "shows validation errors in place, without leaving the editor" do
      subject_page = create(:page, game: game, title: "House Rules")
      sign_in_as(gm)
      visit edit_game_page_path(game, subject_page)

      fill_in "page[title]", with: ""
      click_on "Save"

      expect(page).to have_current_path(edit_game_page_path(game, subject_page))
      expect(subject_page.reload.title).to eq("House Rules")
    end

    it "leaves the editor by cancelling" do
      subject_page = create(:page, game: game, title: "House Rules")
      sign_in_as(gm)
      visit edit_game_page_path(game, subject_page)

      click_on "Cancel"

      expect(page).to have_current_path(game_page_path(game, subject_page))
    end
  end
end
