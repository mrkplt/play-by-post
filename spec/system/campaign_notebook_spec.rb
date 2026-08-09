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
    it "creates, edits inline, moves lanes, and promotes an entry without full page navigation" do
      sign_in_as(gm)
      visit game_path(game)

      find("button[data-tab='notebook']").click
      click_on "New Entry"

      fill_in "notebook_entry[title]", with: "A wandering merchant"
      fill_in "notebook_entry[body]", with: "Shows up in the next market scene."
      click_on "Create Entry"

      expect(page).to have_text("A wandering merchant")

      # Inline edit — no navigation
      current = page.current_path
      click_on "Edit"
      expect(page).to have_field("notebook_entry[title]", with: "A wandering merchant")

      fill_in "notebook_entry[title]", with: "A wandering merchant (updated)"
      click_on "Save"

      expect(page).to have_text("A wandering merchant (updated)")
      expect(page.current_path).to eq(current)

      # Lane move via dropdown — no navigation
      within "#notebook_column_new" do
        select "Expand", from: "notebook_entry[status]"
      end

      expect(page).to have_css("#notebook_column_expand", text: "A wandering merchant (updated)")
      expect(page).to have_no_css("#notebook_column_new", text: "A wandering merchant (updated)")
      expect(page.current_path).to eq(current)

      # Promote to a page
      within "#notebook_column_expand" do
        click_on "Promote"
      end

      expect(page).to have_text("Promoted to: A wandering merchant (updated)")

      promoted_page = Page.find_by(title: "A wandering merchant (updated)")
      expect(promoted_page).to be_present
      expect(promoted_page.body).to eq("Shows up in the next market scene.")
    end

    it "hides the Discard column by default and reveals it via the toggle" do
      create(:notebook_entry, game: game, title: "Scrapped Idea", status: "discard")
      sign_in_as(gm)
      visit game_notebook_entries_path(game)

      expect(page).to have_no_text("Scrapped Idea")

      click_on "Show discarded"

      expect(page).to have_text("Scrapped Idea")
    end

    it "promotes from the entry's own show screen" do
      entry = create(:notebook_entry, game: game, title: "Standalone Idea", body: "Body content.")
      sign_in_as(gm)
      visit game_notebook_entry_path(game, entry)

      click_on "Promote"

      expect(page).to have_text("Promoted to: Standalone Idea")
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
