require "rails_helper"

# The AI Control Plane's per-viewer DISPLAY preference (shown/tagged/hidden):
# independent of ai_summaries_consent (producing) — this controls how the
# viewer's own client renders AI-generated summaries they encounter. Exercises
# the scene screen (badge loudness + hidden filtering) and the members-only
# campaign log (hidden filtering). Viewport-neutral (Path 3) — the control
# and its downstream effect don't diverge by screen size.
RSpec.describe "Scene summary AI display preference", type: :feature do
  let(:game) { create(:game, name: "Sunken Archive") }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game, private: false, title: "The Reckoning") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  it "shows the prominent AI-generated badge to a viewer with the default (tagged) preference" do
    create(:scene_summary, :ai_generated, scene: scene, body: "The AI recap.")

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(page).to have_text("AI-generated")
  end

  it "suppresses the prominent AI-generated badge for a viewer who prefers shown" do
    create(:scene_summary, :ai_generated, scene: scene, body: "The AI recap.")
    player.user_profile.update!(ai_display_preference: :shown)

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(page).to have_text("The AI recap.")
    expect(page).to have_no_text("AI-generated")
  end

  it "hides an AI-generated summary from the scene screen for a viewer who prefers hidden" do
    create(:scene_summary, :ai_generated, scene: scene, body: "The AI recap.")
    player.user_profile.update!(ai_display_preference: :hidden)

    sign_in_as(player)
    visit game_scene_path(game, scene)

    expect(page).to have_no_text("The AI recap.")
  end

  it "hides an AI-generated summary from the members-only campaign log for a viewer who prefers hidden" do
    create(:scene_summary, :ai_generated, scene: scene, body: "The AI recap.")
    hand_scene = create(:scene, :resolved, game: game, private: false, title: "The Aftermath")
    create(:scene_summary, scene: hand_scene, body: "The hand-written recap.")
    player.user_profile.update!(ai_display_preference: :hidden)

    sign_in_as(player)
    visit game_scene_summaries_path(game)

    expect(page).to have_text("The hand-written recap.")
    expect(page).to have_no_text("The AI recap.")
  end
end
