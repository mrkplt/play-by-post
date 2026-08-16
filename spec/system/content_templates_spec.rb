require "rails_helper"

# The template management + seeding flow on both viewports: a GM creates a page
# template, then a new page starts pre-filled with that template's body.
RSpec.describe "Content templates", type: :feature do
  let(:game) { create(:game, name: "Sunken Archive") }
  let(:gm) { create(:user, :with_profile) }

  before { create(:game_member, :game_master, game: game, user: gm) }

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "sets a page template and pre-fills a new page from it" do
        sign_in_as(gm)
        visit new_game_content_template_path(game)

        select "Page", from: "content_template[content_type]"
        fill_in "content_template[body]", with: "## Standard page layout"
        click_on "Create Template"

        expect(page).to have_text("Template saved.")
        expect(game.content_templates.find_by(content_type: "page").body).to eq("## Standard page layout")

        visit new_game_page_path(game)
        expect(page).to have_field("page[body]", with: "## Standard page layout")
      end
    end
  end
end
