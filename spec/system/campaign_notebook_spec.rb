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

    it "edits an entry from its edit screen" do
      entry = create(:notebook_entry, game: game, title: "A wandering merchant")
      sign_in_as(gm)
      visit edit_game_notebook_entry_path(game, entry)

      fill_in "notebook_entry[title]", with: "A wandering merchant (updated)"
      click_on "Save"

      expect(page).to have_text("Entry updated.")
      expect(entry.reload.title).to eq("A wandering merchant (updated)")
    end

    it "writes into a large editor with no live preview" do
      entry = create(:notebook_entry, game: game, title: "A wandering merchant")
      sign_in_as(gm)
      visit edit_game_notebook_entry_path(game, entry)

      expect(page).to have_css("textarea[name='notebook_entry[body]']")
      expect(page).to have_css("[role='toolbar'][aria-label='Markdown formatting']")
      expect(page).to have_no_css("[data-markdown-preview-target='preview']")
    end

    it "gives the entry actions >= 44px touch targets" do
      entry = create(:notebook_entry, game: game, title: "Doomed Idea")
      resize_window_to_viewport(*ViewportHelper::VIEWPORTS.fetch("mobile (375px)"))
      sign_in_as(gm)
      visit edit_game_notebook_entry_path(game, entry)

      # Promote and Delete sit side by side and Delete is irreversible, so both
      # need a real target — as bare text they were 16px tall and mis-tapped.
      %w[Promote Delete].each do |label|
        height = page.evaluate_script(<<~JS)
          Array.from(document.querySelectorAll('button'))
            .find(b => b.textContent.trim() === '#{label}')
            .getBoundingClientRect().height
        JS
        expect(height).to be >= 44, "expected #{label} to have a >= 44px touch target, got #{height}px"
      end
    end

    it "renders each lane heading once no matter how many moves the GM makes" do
      create(:notebook_entry, game: game, title: "A wandering merchant", status: "new")
      sign_in_as(gm)
      visit game_notebook_entries_path(game)

      3.times do |i|
        destination = i.even? ? "Expand" : "New"
        source_column = i.even? ? "#notebook_column_new" : "#notebook_column_expand"

        within source_column do
          select destination, from: "notebook_entry[status]"
        end

        expect(page).to have_css("#notebook_column_#{destination.downcase}", text: "A wandering merchant")
      end

      # A lane replaced by the move stream must not accumulate a heading each
      # time. The headings nest, so this counts the heading elements themselves
      # rather than asserting on text an ancestor also contains.
      # Uppercased by CSS, so match what the GM actually reads on screen.
      %w[NEW EXPAND DONE].each do |heading|
        expect(page).to have_css("[data-section-label]", exact_text: heading, count: 1)
      end
    end

    it "moves an entry between lanes from its edit screen" do
      entry = create(:notebook_entry, game: game, title: "A wandering merchant", status: "new")
      sign_in_as(gm)
      visit edit_game_notebook_entry_path(game, entry)

      select "Expand", from: "notebook_entry[status]"

      # Assert the confirmation, not the select's value — the select already
      # reads "Expand" from the click itself, so it passes even when the
      # response is discarded and the GM sees nothing happen.
      expect(page).to have_text("Entry moved.")
      expect(entry.reload.status).to eq("expand")
    end

    it "promotes an entry from its edit screen" do
      entry = create(:notebook_entry, game: game, title: "Standalone Idea", body: "Body content.")
      sign_in_as(gm)
      visit edit_game_notebook_entry_path(game, entry)

      click_on "Promote"

      expect(page).to have_current_path(%r{/games/\d+/pages/})
      expect(Page.find_by(title: "Standalone Idea")).to be_present
    end

    it "deletes an entry from its edit screen" do
      entry = create(:notebook_entry, game: game, title: "Doomed Idea")
      sign_in_as(gm)
      visit edit_game_notebook_entry_path(game, entry)

      accept_confirm { click_on "Delete" }

      expect(page).to have_current_path(game_notebook_entries_path(game))
      expect(NotebookEntry.find_by(id: entry.id)).to be_nil
    end

    it "hides the Discard column by default and reveals it via the toggle" do
      create(:notebook_entry, game: game, title: "Scrapped Idea", status: "discard")
      sign_in_as(gm)
      visit game_notebook_entries_path(game)

      expect(page).to have_no_text("Scrapped Idea")

      find("summary", text: "Show discarded").click

      expect(page).to have_text("Scrapped Idea")
    end

    it "links to the page an entry became, instead of offering Promote twice" do
      entry = create(:notebook_entry, game: game, title: "Standalone Idea", body: "Body content.")
      sign_in_as(gm)
      visit edit_game_notebook_entry_path(game, entry)
      click_on "Promote"

      visit edit_game_notebook_entry_path(game, entry)

      expect(page).to have_no_button("Promote")
      expect(page).to have_link("Promoted to: Standalone Idea")
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

      expect(page).to have_current_path(root_path)
      expect(page).to have_text("You are not authorized to perform this action.")
    end
  end
end
