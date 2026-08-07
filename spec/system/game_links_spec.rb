require "rails_helper"

RSpec.describe "Game Links", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "Links tab on the game screen" do
    it "shows the off-site warning when opened" do
      sign_in_as(player)
      visit game_path(game)

      find("button[data-tab='links']").click

      expect(page).to have_text("Warning: Links point off this site.")
      expect(page).to have_text("No links yet.")
    end

    it "lists a link pointing at its external URL" do
      create(:game_link, game: game, description: "Map", url: "https://example.com/map")
      sign_in_as(player)
      visit game_path(game)

      find("button[data-tab='links']").click

      expect(page).to have_link("Map", href: "https://example.com/map")
    end

    it "exposes the Links tab to the GM and to non-GM members" do
      sign_in_as(gm)
      visit game_path(game)
      expect(page).to have_css("button[data-tab='links']", text: "Links")

      sign_in_as(player)
      visit game_path(game)
      expect(page).to have_css("button[data-tab='links']", text: "Links")
    end
  end

  describe "Links index page" do
    it "shows the warning and the links to a member" do
      create(:game_link, game: game, description: "Map", url: "https://example.com/map")
      sign_in_as(player)
      visit game_game_links_path(game)

      expect(page).to have_text("Warning: Links point off this site.")
      expect(page).to have_link("Map", href: "https://example.com/map")
    end

    it "blocks a banned user" do
      banned_user = create(:user, :with_profile)
      create(:game_member, :banned, game: game, user: banned_user)

      sign_in_as(banned_user)
      visit game_game_links_path(game)

      expect(page).to have_current_path(root_path)
      expect(page).to have_text("You do not have access")
    end
  end

  describe "GM link management" do
    it "GM can create a link and it appears on the game screen and index" do
      sign_in_as(gm)
      visit game_game_links_path(game)

      click_on "New Link"
      fill_in "game_link[description]", with: "Session Zero Notes"
      fill_in "game_link[url]", with: "https://docs.example.com/session-zero"
      click_on "Create Link"

      expect(page).to have_text("Link added.")
      expect(page).to have_link("Session Zero Notes", href: "https://docs.example.com/session-zero")

      visit game_path(game)
      find("button[data-tab='links']").click
      expect(page).to have_link("Session Zero Notes", href: "https://docs.example.com/session-zero")
    end

    it "GM can edit a link" do
      create(:game_link, game: game, description: "Old", url: "https://example.com/old")
      sign_in_as(gm)
      visit game_game_links_path(game)

      click_on "Edit"
      fill_in "game_link[description]", with: "New"
      fill_in "game_link[url]", with: "https://example.com/new"
      click_on "Save"

      expect(page).to have_text("Link updated.")
      expect(page).to have_link("New", href: "https://example.com/new")
    end

    it "GM can delete a link", :js do
      create(:game_link, game: game, description: "Doomed", url: "https://example.com/doomed")
      sign_in_as(gm)
      visit game_game_links_path(game)

      accept_confirm("Delete this link?") do
        click_on "Delete"
      end

      expect(page).to have_text("Link deleted.")
      expect(page).to have_text("No links yet.")
    end

    it "non-GM sees no New Link / Edit / Delete affordances" do
      create(:game_link, game: game, description: "Map", url: "https://example.com/map")
      sign_in_as(player)
      visit game_game_links_path(game)

      expect(page).to have_no_link("New Link")
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Delete")
    end

    it "rejects a non-http URL with an inline error" do
      sign_in_as(gm)
      visit game_game_links_path(game)

      click_on "New Link"
      fill_in "game_link[description]", with: "Sketchy"
      fill_in "game_link[url]", with: "javascript:alert(1)"
      click_on "Create Link"

      expect(page).to have_text("Url must be a valid http(s) URL")
    end
  end
end
