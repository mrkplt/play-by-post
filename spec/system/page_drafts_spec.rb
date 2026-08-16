require "rails_helper"

# The page draft → publish flow, exercised on both viewports: a GM creates a
# page as a draft, sees the Draft badge and no player-facing exposure, then
# publishes it. Save-as-draft on create sets the flag; Publish promotes the row.
RSpec.describe "Page drafts", type: :feature do
  let(:game) { create(:game, name: "Sunken Archive") }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "creates a draft page and publishes it" do
        sign_in_as(gm)
        visit new_game_page_path(game)

        fill_in "page[title]", with: "Secret Lore"
        check "page[draft]"
        click_on "Create Page"

        # Wait on the detail screen (the Publish affordance appears only on a
        # draft) before reading the record — click_on returns as soon as the
        # request is issued, so querying first races the redirect.
        expect(page).to have_button("Publish")
        created = game.pages.find_by!(title: "Secret Lore")
        expect(created.draft).to be(true)

        click_on "Publish"

        expect(page).to have_text("Page published.")
        expect(created.reload.draft).to be(false)
      end
    end
  end

  it "hides a draft page from a player's Pages tab" do
    create(:page, game: game, title: "Player-hidden draft", draft: true)
    create(:page, game: game, title: "Published page", draft: false)

    sign_in_as(player)
    visit game_path(game, anchor: "pages")

    expect(page).to have_text("Published page")
    expect(page).to have_no_text("Player-hidden draft")
  end
end
