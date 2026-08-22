require "rails_helper"

# The async "pending backend item" flow on both viewports (Fizzy #115/#116): on a
# resolved, AI-enabled scene whose SceneSummaryJob has not finished, the viewer
# sees a spinner + "Generating…"; the scene page subscribes that viewer to their
# visibility-class Turbo Stream, and when the worker broadcasts the finished
# summary the pending frame is replaced in place and a completion toast appears.
# Presence-only — every viewer of the pending page subscribes; there is no
# per-initiator state.
RSpec.describe "Async scene summary", type: :feature do
  let(:game) { create(:game, name: "Sunken Archive", ai_summaries_enabled: true) }
  let(:gm) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game, private: false, title: "The Reckoning") }

  before { create(:game_member, :game_master, game: game, user: gm) }

  ViewportHelper::VIEWPORTS.each do |label, (width, height)|
    context "at #{label}" do
      before { resize_window_to_viewport(width, height) }

      it "shows a spinner then swaps in the broadcast summary with a toast" do
        sign_in_as(gm)
        visit game_scene_path(game, scene)

        expect(page).to have_text("Generating scene summary…")
        expect(page).to have_css("#scene_summary_pending span[role='status']")

        # Wait for the browser's cable socket to connect before broadcasting, so
        # the swap is observed rather than raced.
        connect_turbo_cable_stream_sources

        # Stand in for SceneSummaryJob completing in the worker: create the row
        # and broadcast it to the waiting viewers.
        summary = create(:scene_summary, scene: scene, body: "The vault finally gave.", draft: false)
        SceneSummaryBroadcast.new(summary).call

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
