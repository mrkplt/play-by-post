require "rails_helper"

RSpec.describe "Mobile post composer", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    sign_in_as(gm)
    page.driver.resize_window_to(page.driver.current_window_handle, 375, 812)
  end

  it "post composition form is visible at 375px" do
    visit game_scene_path(game, scene)
    expect(page).to have_css("textarea", visible: true)
  end

  it "textarea has font-size of at least 16px to prevent iOS auto-zoom" do
    visit game_scene_path(game, scene)
    font_size = page.evaluate_script(
      "parseFloat(window.getComputedStyle(document.querySelector('textarea')).fontSize)"
    )
    expect(font_size).to be >= 16
  end

  it "Submit button has a minimum height of 44px" do
    visit game_scene_path(game, scene)
    height = page.evaluate_script(
      "parseFloat(window.getComputedStyle(document.querySelector('input[type=\"submit\"]')).minHeight)"
    )
    expect(height).to be >= 44
  end

  it "action buttons are stacked vertically on narrow screen" do
    visit game_scene_path(game, scene)
    flex_direction = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.post-composer-actions')).flexDirection"
    )
    expect(flex_direction).to eq("column")
  end
end
