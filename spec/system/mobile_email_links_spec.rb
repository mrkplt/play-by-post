require "rails_helper"

RSpec.describe "Mobile email deep links", type: :feature do
  let(:gm) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game, title: "The Dark Forest") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    page.driver.resize(375, 812)
  end

  it "deep link to scene renders the correct scene in mobile viewport" do
    sign_in_as(gm)
    visit game_scene_path(game, scene)
    expect(page).to have_text("The Dark Forest")
    scroll_width = page.evaluate_script("document.body.scrollWidth")
    expect(scroll_width).to be <= 375
  end

  it "page has a viewport meta tag" do
    sign_in_as(gm)
    visit game_scene_path(game, scene)
    viewport_meta = page.evaluate_script(
      "document.querySelector('meta[name=\"viewport\"]') !== null"
    )
    expect(viewport_meta).to be true
  end

  it "unauthenticated deep link redirects to sign-in then back to target" do
    visit game_scene_path(game, scene)
    expect(page).to have_current_path(new_user_session_path)
    sign_in_as(gm)
    expect(page).to have_text("The Dark Forest")
  end
end
