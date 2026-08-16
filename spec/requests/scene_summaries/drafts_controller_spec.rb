require "rails_helper"

# SceneSummaries::DraftsController is the summary-specific adopter of
# Draftable::Controller: it wires save/publish to the shared helpers and
# supplies the summary lookup, params, redirect, and access guard. The shared
# behaviour is exercised in spec/requests/draftable/controller_spec.rb; this
# spec pins the summary-specific wiring.
RSpec.describe SceneSummaries::DraftsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:outsider) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:scene) { create(:scene, :resolved, game: game) }
  let!(:summary) { create(:scene_summary, scene: scene, body: "old") }

  before { create(:game_member, :game_master, game: game, user: gm) }

  describe "PATCH save" do
    it "autosaves the summary as a draft with the submitted body" do
      sign_in(gm)

      patch save_draft_game_scene_scene_summary_path(game, scene),
            params: { scene_summary: { body: "new body" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(summary.reload.draft).to be(true)
      expect(summary.body).to eq("new body")
    end

    it "denies a non-member" do
      sign_in(outsider)

      patch save_draft_game_scene_scene_summary_path(game, scene),
            params: { scene_summary: { body: "x" } }, as: :json

      expect(response).to redirect_to(root_path)
      expect(summary.reload.draft).to be(false)
    end
  end

  describe "PATCH publish" do
    let!(:summary) { create(:scene_summary, scene: scene, draft: true) }

    it "publishes the summary and redirects to the scene" do
      sign_in(gm)

      patch publish_game_scene_scene_summary_path(game, scene)

      expect(summary.reload.draft).to be(false)
      expect(response).to redirect_to(game_scene_path(game, scene))
      expect(flash[:notice]).to eq("Summary published.")
    end

    it "denies a non-member" do
      sign_in(outsider)

      patch publish_game_scene_scene_summary_path(game, scene)

      expect(response).to redirect_to(root_path)
      expect(summary.reload.draft).to be(true)
    end
  end
end
