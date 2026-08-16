require "rails_helper"

# The scene-summary draft → publish flow on both viewports: a GM has a draft
# summary, sees the Draft badge and Publish affordance on the scene, publishes
# it, and it becomes visible. Also confirms a draft never reaches the
# members-only campaign log.
RSpec.describe "Scene summary drafts", type: :feature do
  let(:game) { create(:game, name: "Sunken Archive") }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game, private: false, title: "The Reckoning") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "publishes a draft summary from the scene screen" do
        summary = create(:scene_summary, scene: scene, body: "A hidden draft.", draft: true)

        sign_in_as(gm)
        visit game_scene_path(game, scene)

        expect(page).to have_button("Publish")
        click_on "Publish"

        expect(page).to have_text("Summary published.")
        expect(summary.reload.draft).to be(false)
      end
    end
  end

  it "keeps a draft summary out of the members-only campaign log" do
    create(:scene_summary, scene: scene, body: "Draft not for players.", draft: true)
    published_scene = create(:scene, :resolved, game: game, private: false)
    create(:scene_summary, scene: published_scene, body: "Published for everyone.", draft: false)

    sign_in_as(player)
    visit game_scene_summaries_path(game)

    expect(page).to have_text("Published for everyone.")
    expect(page).to have_no_text("Draft not for players.")
  end
end
