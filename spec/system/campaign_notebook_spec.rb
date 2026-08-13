require "rails_helper"

RSpec.describe "Campaign Notebook", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GM workflow", :js do
    it "creates an entry and moves it between lanes without leaving the board" do
      sign_in_as(gm)
      visit game_path(game)

      find("button[data-tab='notebook']").click
      click_on "New Entry"

      fill_in "notebook_entry[title]", with: "A wandering merchant"
      fill_in "notebook_entry[body]", with: "Shows up in the next market scene."
      click_on "Create Entry"

      expect(page).to have_text("A wandering merchant")

      visit game_notebook_entries_path(game)
      board_path = page.current_path

      # Lane move via dropdown — no navigation
      within "#notebook_column_new" do
        select "Expand", from: "notebook_entry[status]"
      end

      expect(page).to have_css("#notebook_column_expand", text: "A wandering merchant")
      expect(page).to have_no_css("#notebook_column_new", text: "A wandering merchant")
      expect(page.current_path).to eq(board_path)
    end

    it "opens an entry's edit screen by clicking its title on the board" do
      entry = create(:notebook_entry, game: game, title: "A wandering merchant")
      sign_in_as(gm)
      visit game_notebook_entries_path(game)

      click_on "A wandering merchant"

      expect(page).to have_current_path(edit_game_notebook_entry_path(game, entry))
      expect(page).to have_field("notebook_entry[title]", with: "A wandering merchant")
    end

    it "shows only the lane picker on a board row" do
      create(:notebook_entry, game: game, title: "A wandering merchant")
      sign_in_as(gm)
      visit game_notebook_entries_path(game)

      expect(page).to have_css("select[name='notebook_entry[status]']")
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Promote")
      expect(page).to have_no_button("Delete")
    end

    it "hides the Discard column by default and reveals it via the toggle" do
      create(:notebook_entry, game: game, title: "Scrapped Idea", status: "discard")
      sign_in_as(gm)
      visit game_notebook_entries_path(game)

      expect(page).to have_no_text("Scrapped Idea")

      find("summary", text: "Show discarded").click

      expect(page).to have_text("Scrapped Idea")
    end

    it "promotes from the entry's own show screen" do
      entry = create(:notebook_entry, game: game, title: "Standalone Idea", body: "Body content.")
      sign_in_as(gm)
      visit game_notebook_entry_path(game, entry)

      click_on "Promote"

      expect(page).to have_text("Promoted to a page.")
      expect(Page.find_by(title: "Standalone Idea")).to be_present
    end
  end

  describe "player access" do
    it "does not show a Notebook tab or nav item" do
      sign_in_as(player)
      visit game_path(game)

      expect(page).to have_no_css("button[data-tab='notebook']")
    end

    it "redirects direct navigation to the notebook index away" do
      sign_in_as(player)
      visit game_notebook_entries_path(game)

      expect(page).to have_current_path(game_path(game))
      expect(page).to have_text("Only the GM can access the notebook.")
    end
  end
end
