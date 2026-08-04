require "rails_helper"

# Email deep-link landing behaviour, verified on both a phone and a desktop
# browser. (Was mobile_email_links_spec, mobile-only.)
RSpec.describe "Email deep links (responsive)", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game, title: "The Dark Forest") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
  end

  it "redirects an unauthenticated deep link to sign-in" do
    visit game_scene_path(game, scene)
    expect(page).to have_current_path(new_user_session_path)
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "renders the deep-linked scene without horizontal scroll" do
        sign_in_as(gm)
        visit game_scene_path(game, scene)
        expect(page).to have_text("The Dark Forest")
        scroll_width = page.evaluate_script("document.body.scrollWidth")
        expect(scroll_width).to be <= width
      end

      it "includes a viewport meta tag" do
        sign_in_as(gm)
        visit game_scene_path(game, scene)
        viewport_meta = page.evaluate_script(
          "document.querySelector('meta[name=\"viewport\"]') !== null"
        )
        expect(viewport_meta).to be true
      end
    end
  end
end
