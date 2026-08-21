require "rails_helper"

# The async "pending backend item" flow on both viewports (Fizzy #115): on a
# resolved, AI-enabled scene whose SceneSummaryJob has not finished, the viewer
# sees a spinner + "Generating…"; once the summary row lands the polled frame
# swaps it in place and a completion toast appears. Presence-only — every viewer
# of the pending page polls; there is no per-initiator state.
RSpec.describe "Async scene summary", type: :feature do
  let(:game) { create(:game, name: "Sunken Archive", ai_summaries_enabled: true) }
  let(:gm) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game, private: false, title: "The Reckoning") }

  before { create(:game_member, :game_master, game: game, user: gm) }

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "shows a spinner then swaps in the summary with a toast when the job finishes" do
        sign_in_as(gm)
        visit game_scene_path(game, scene)

        expect(page).to have_text("Generating scene summary…")
        expect(page).to have_css("#scene_summary_pending span[role='status']")

        # Stand in for SceneSummaryJob completing in the worker. The frame polls
        # on an interval, so give the swap generous time to be picked up.
        create(:scene_summary, scene: scene, body: "The vault finally gave.", draft: false)

        expect(page).to have_text("The vault finally gave.", wait: 8)
        expect(page).to have_text("Scene summary ready.", wait: 8)
        expect(page).to have_no_text("Generating scene summary…")
      end
    end
  end

  it "renders nothing pending when the game has AI summaries off" do
    game.update!(ai_summaries_enabled: false)

    sign_in_as(gm)
    visit game_scene_path(game, scene)

    expect(page).to have_no_text("Generating scene summary…")
    expect(page).to have_no_css("#scene_summary_pending")
  end
end
