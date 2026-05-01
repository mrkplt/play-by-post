require "rails_helper"

RSpec.describe SceneSummariesController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:resolved_scene) { create(:scene, :resolved, game: game) }
  let(:active_scene) { create(:scene, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  # ── index (HTML) ──────────────────────────────────────────────────────────

  describe "GET /games/:game_id/scene_summaries" do
    it "returns 200 for a GM" do
      sign_in(gm)
      get game_scene_summaries_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 for a player" do
      sign_in(player)
      get game_scene_summaries_path(game)
      expect(response).to have_http_status(:ok)
    end

    it "redirects unauthenticated users" do
      get game_scene_summaries_path(game)
      expect(response).to have_http_status(:redirect)
    end

    it "shows summaries for public resolved scenes" do
      summary = create(:scene_summary, scene: resolved_scene)
      sign_in(player)
      get game_scene_summaries_path(game)
      expect(response.body).to include(summary.body)
    end

    it "does not show summaries for private scenes" do
      private_scene = create(:scene, :resolved, game: game, private: true)
      summary = create(:scene_summary, scene: private_scene)
      sign_in(player)
      get game_scene_summaries_path(game)
      expect(response.body).not_to include(summary.body)
    end

    it "redirects a removed member who is not signed in" do
      removed_user = create(:user, :with_profile)
      create(:game_member, :removed, game: game, user: removed_user)
      get game_scene_summaries_path(game)
      expect(response).to have_http_status(:redirect)
    end

    it "returns 200 for a removed member who is signed in" do
      removed_user = create(:user, :with_profile)
      create(:game_member, :removed, game: game, user: removed_user)
      sign_in(removed_user)
      get game_scene_summaries_path(game)
      expect(response).to have_http_status(:ok)
    end
  end

  # ── index (RSS) ───────────────────────────────────────────────────────────

  describe "GET /games/:game_id/scene_summaries.rss" do
    it "returns 200 for an active member (session auth)" do
      sign_in(player)
      get game_scene_summaries_path(game, format: :rss)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/rss+xml")
    end

    it "returns 200 with a valid RSS token" do
      rss_token = create(:rss_token, user: player)
      get game_scene_summaries_path(game, format: :rss, token: rss_token.token)
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 with no token and no session" do
      get game_scene_summaries_path(game, format: :rss)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a revoked/invalid token" do
      get game_scene_summaries_path(game, format: :rss, token: "bogus-token")
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when token owner is not a game member" do
      outsider = create(:user, :with_profile)
      rss_token = create(:rss_token, user: outsider)
      get game_scene_summaries_path(game, format: :rss, token: rss_token.token)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ── new ───────────────────────────────────────────────────────────────────

  describe "GET /games/:game_id/scenes/:scene_id/scene_summary/new" do
    it "returns 200 for GM on a resolved scene" do
      sign_in(gm)
      get new_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to have_http_status(:ok)
    end

    it "redirects a player" do
      sign_in(player)
      get new_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to redirect_to(game_path(game))
    end

    it "redirects GM on an unresolved scene" do
      sign_in(gm)
      get new_game_scene_scene_summary_path(game, active_scene)
      expect(response).to redirect_to(game_scene_path(game, active_scene))
    end
  end

  # ── create ────────────────────────────────────────────────────────────────

  describe "POST /games/:game_id/scenes/:scene_id/scene_summary" do
    it "creates a summary and redirects GM with notice" do
      sign_in(gm)
      expect {
        post game_scene_scene_summary_path(game, resolved_scene),
             params: { scene_summary: { body: "Summary text." } }
      }.to change(SceneSummary, :count).by(1)
      expect(response).to redirect_to(game_scene_path(game, resolved_scene))
      expect(flash[:notice]).to match(/saved/i)
      summary = SceneSummary.find_by!(scene: resolved_scene)
      expect(summary.edited_by).to eq(gm)
      expect(summary.edited_at).to be_present
    end

    it "rejects a player" do
      sign_in(player)
      post game_scene_scene_summary_path(game, resolved_scene),
           params: { scene_summary: { body: "Summary text." } }
      expect(response).to redirect_to(game_path(game))
    end

    it "renders new on invalid params" do
      sign_in(gm)
      post game_scene_scene_summary_path(game, resolved_scene),
           params: { scene_summary: { body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "redirects to edit when summary already exists with alert" do
      create(:scene_summary, scene: resolved_scene)
      sign_in(gm)
      post game_scene_scene_summary_path(game, resolved_scene),
           params: { scene_summary: { body: "Duplicate." } }
      expect(response).to redirect_to(edit_game_scene_scene_summary_path(game, resolved_scene))
      expect(flash[:alert]).to be_present
    end
  end

  # ── edit ──────────────────────────────────────────────────────────────────

  describe "GET /games/:game_id/scenes/:scene_id/scene_summary/edit" do
    it "returns 200 for GM with existing summary" do
      create(:scene_summary, scene: resolved_scene)
      sign_in(gm)
      get edit_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to have_http_status(:ok)
    end

    it "redirects with alert when no summary exists" do
      sign_in(gm)
      get edit_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to redirect_to(game_scene_path(game, resolved_scene))
      expect(flash[:alert]).to be_present
    end
  end

  describe "require_resolved_scene! guard" do
    it "redirects GM with alert on an unresolved scene" do
      sign_in(gm)
      get new_game_scene_scene_summary_path(game, active_scene)
      expect(response).to redirect_to(game_scene_path(game, active_scene))
      expect(flash[:alert]).to be_present
    end
  end

  describe "require_gm! guard" do
    it "redirects a player with alert" do
      sign_in(player)
      get new_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to be_present
    end
  end

  # ── update ────────────────────────────────────────────────────────────────

  describe "PATCH /games/:game_id/scenes/:scene_id/scene_summary" do
    let!(:summary) { create(:scene_summary, :ai_generated, scene: resolved_scene) }

    it "updates body and clears AI metadata with notice" do
      sign_in(gm)
      patch game_scene_scene_summary_path(game, resolved_scene),
            params: { scene_summary: { body: "Edited text." } }
      expect(response).to redirect_to(game_scene_path(game, resolved_scene))
      expect(flash[:notice]).to match(/updated/i)
      summary.reload
      expect(summary.body).to eq("Edited text.")
      expect(summary.generated_at).to be_nil
      expect(summary.model_used).to be_nil
      expect(summary.input_tokens).to be_nil
      expect(summary.output_tokens).to be_nil
      expect(summary.edited_by).to eq(gm)
      expect(summary.edited_at).to be_present
    end

    it "rejects a player" do
      sign_in(player)
      patch game_scene_scene_summary_path(game, resolved_scene),
            params: { scene_summary: { body: "Edited." } }
      expect(response).to redirect_to(game_path(game))
    end
  end

  # ── destroy ───────────────────────────────────────────────────────────────

  describe "DELETE /games/:game_id/scenes/:scene_id/scene_summary" do
    let!(:summary) { create(:scene_summary, scene: resolved_scene) }

    it "destroys the summary as GM with notice" do
      sign_in(gm)
      expect {
        delete game_scene_scene_summary_path(game, resolved_scene)
      }.to change(SceneSummary, :count).by(-1)
      expect(response).to redirect_to(game_scene_path(game, resolved_scene))
      expect(flash[:notice]).to match(/deleted/i)
    end

    it "rejects a player" do
      sign_in(player)
      delete game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to redirect_to(game_path(game))
    end
  end
end
