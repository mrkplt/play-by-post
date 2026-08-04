require "rails_helper"

# Post-composer ergonomics that must hold at every viewport, verified on both a
# phone and a desktop browser. (Was mobile_composer_spec, mobile-only.)
RSpec.describe "Post composer (responsive)", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    sign_in_as(gm)
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "shows the composition form" do
        visit game_scene_path(game, scene)
        expect(page).to have_css("textarea", visible: true)
      end

      it "renders the textarea at >= 16px (no iOS auto-zoom)" do
        visit game_scene_path(game, scene)
        font_size = page.evaluate_script(
          "parseFloat(window.getComputedStyle(document.querySelector('textarea')).fontSize)"
        )
        expect(font_size).to be >= 16
      end

      it "gives the Submit button a >= 44px touch target" do
        visit game_scene_path(game, scene)
        submit_height = page.evaluate_script(
          "parseFloat(window.getComputedStyle(document.querySelector('#post_composer input[type=\"submit\"]')).minHeight)"
        )
        expect(submit_height).to be >= 44
      end

      it "lays out the action buttons in a row" do
        visit game_scene_path(game, scene)
        flex_direction = page.evaluate_script(
          "window.getComputedStyle(document.querySelector('[data-testid=\"composer-actions\"]')).flexDirection"
        )
        expect(flex_direction).to eq("row")
      end
    end
  end
end
