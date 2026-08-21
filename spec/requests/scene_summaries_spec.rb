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

  it_behaves_like "a slug-addressed game action" do
    let(:signed_in_user) { gm }
    def perform_request(game_id) = get game_scene_summaries_path(game_id)
  end

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

    it "excludes AI-generated summaries when the viewer's AI display preference is hidden" do
      ai_summary = create(:scene_summary, :ai_generated, scene: resolved_scene, body: "AI-written recap.")
      hand_scene = create(:scene, :resolved, game: game)
      hand_written = create(:scene_summary, scene: hand_scene, body: "Hand-written recap.")
      player.user_profile.update!(ai_display_preference: :hidden)

      sign_in(player)
      get game_scene_summaries_path(game)

      expect(response.body).to include(hand_written.body)
      expect(response.body).not_to include(ai_summary.body)
    end

    it "shows AI-generated summaries when the viewer's AI display preference is tagged" do
      ai_summary = create(:scene_summary, :ai_generated, scene: resolved_scene, body: "AI-written recap.")
      player.user_profile.update!(ai_display_preference: :tagged)

      sign_in(player)
      get game_scene_summaries_path(game)

      expect(response.body).to include(ai_summary.body)
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

    it "redirects a banned member to root" do
      banned_user = create(:user, :with_profile)
      create(:game_member, :banned, game: game, user: banned_user)
      sign_in(banned_user)
      get game_scene_summaries_path(game)
      expect(response).to redirect_to(root_path)
    end

    # Asserting the message, not just the redirect: Pundit's own denial also
    # lands on root_path, so without this the spec passes even with
    # require_game_access! deleted entirely.
    it "redirects a signed-in non-member to root" do
      outsider = create(:user, :with_profile)
      sign_in(outsider)
      get game_scene_summaries_path(game)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You do not have access to this game.")
    end

    it "returns summaries ordered by resolved_at descending" do
      older_scene = create(:scene, :resolved, game: game, resolved_at: 2.days.ago)
      newer_scene = create(:scene, :resolved, game: game, resolved_at: 1.day.ago)
      older_summary = create(:scene_summary, scene: older_scene, body: "Older summary")
      newer_summary = create(:scene_summary, scene: newer_scene, body: "Newer summary")
      sign_in(player)
      get game_scene_summaries_path(game)
      older_pos = response.body.index(older_summary.body)
      newer_pos = response.body.index(newer_summary.body)
      expect(newer_pos).to be < older_pos
    end

    it "renders the universal header nav affordances" do
      sign_in(player)
      get game_scene_summaries_path(game)
      expect_hamburger_present
      expect_breadcrumb(game.name)
      expect_active_tab("Scenes")
    end

    it "renders visible text on the Edit Game page-action button for the GM" do
      sign_in(gm)
      get game_scene_summaries_path(game)
      expect(response.body).to include(">Edit Game<")
    end

    it "does not render the Edit Game page-action button for a player" do
      sign_in(player)
      get game_scene_summaries_path(game)
      expect(response.body).not_to include(">Edit Game<")
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
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end

    it "redirects GM on an unresolved scene" do
      sign_in(gm)
      get new_game_scene_scene_summary_path(game, active_scene)
      expect(response).to redirect_to(game_scene_path(game, active_scene))
    end

    it "renders the universal header nav affordances" do
      sign_in(gm)
      get new_game_scene_scene_summary_path(game, resolved_scene)
      expect_hamburger_present
      expect_breadcrumb(game.name)
    end

    it "renders visible text on the primary and cancel page-action buttons" do
      sign_in(gm)
      get new_game_scene_scene_summary_path(game, resolved_scene)
      expect(response.body).to include(">Save Summary<")
      expect(response.body).to include(">Cancel<")
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
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
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

    it "renders the universal header nav affordances" do
      create(:scene_summary, scene: resolved_scene)
      sign_in(gm)
      get edit_game_scene_scene_summary_path(game, resolved_scene)
      expect_hamburger_present
      expect_breadcrumb(game.name)
    end

    it "renders visible text on the primary and cancel page-action buttons" do
      create(:scene_summary, scene: resolved_scene)
      sign_in(gm)
      get edit_game_scene_scene_summary_path(game, resolved_scene)
      expect(response.body).to include(">Update Summary<")
      expect(response.body).to include(">Cancel<")
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

  describe "require_game_access! guard" do
    it "redirects a non-member to root with alert" do
      outsider = create(:user, :with_profile)
      sign_in(outsider)
      get new_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it "redirects a banned member to root with alert" do
      banned_user = create(:user, :with_profile)
      create(:game_member, :banned, game: game, user: banned_user)
      sign_in(banned_user)
      get new_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to redirect_to(root_path)
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
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end

    it "renders edit with 422 on validation failure" do
      sign_in(gm)
      patch game_scene_scene_summary_path(game, resolved_scene),
            params: { scene_summary: { body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
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
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end
  end

  describe "GET /games/:game_id/scenes/:scene_id/scene_summary/status" do
    def get_status(user)
      sign_in(user)
      get status_game_scene_scene_summary_path(game, resolved_scene)
    end

    it "renders the pending spinner frame when no summary exists yet" do
      get_status(gm)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("turbo-frame")
      expect(response.body).to include('id="scene_summary_pending"')
      expect(response.body).to include("data-controller=\"job-status\"")
      # The poller re-fetches this exact scene's status path (game + scene).
      expect(response.body).to include(status_game_scene_scene_summary_path(game, resolved_scene))
      expect(response.body).not_to include("Scene summary ready.")
    end

    it "renders the summary and drops polling once it exists" do
      summary = create(:scene_summary, scene: resolved_scene)
      get_status(gm)

      expect(response.body).to include(summary.body)
      expect(response.body).not_to include("data-controller=\"job-status\"")
    end

    it "renders the summary through the viewer's AI display preference" do
      create(:scene_summary, :ai_generated, scene: resolved_scene)
      gm.user_profile.update!(ai_display_preference: :shown)
      get_status(gm)

      # A "shown"-preference viewer sees the summary but not the loud badge —
      # only reachable when the viewer is threaded into the presenter.
      expect(response.body).not_to include("AI-generated")
    end

    it "raises the completion notice into the toast layer when ready" do
      create(:scene_summary, scene: resolved_scene)
      get_status(gm)

      expect(response.body).to include("Scene summary ready.")
      expect(response.body).to include('target="toast_layer"')
    end

    it "shows the completion notice only on this response, never persisting it" do
      create(:scene_summary, scene: resolved_scene)
      get_status(gm)
      expect(response.body).to include("Scene summary ready.")

      # flash.now must not survive: the very next page carries no leftover notice.
      get game_scene_path(game, resolved_scene)
      expect(flash[:notice]).to be_nil
    end

    it "keeps polling for a player while the summary is only a draft" do
      create(:scene_summary, scene: resolved_scene, draft: true, body: "")
      get_status(player)

      expect(response.body).to include("data-controller=\"job-status\"")
      expect(response.body).not_to include("Scene summary ready.")
    end

    it "shows a draft summary as ready to the GM" do
      create(:scene_summary, scene: resolved_scene, draft: true, body: "draft prose")
      get_status(gm)

      expect(response.body).to include("draft prose")
      expect(response.body).not_to include("data-controller=\"job-status\"")
    end

    it "keeps polling for a hidden-preference viewer while the only summary is AI-generated" do
      create(:scene_summary, :ai_generated, scene: resolved_scene)
      player.user_profile.update!(ai_display_preference: :hidden)
      get_status(player)

      expect(response.body).to include("data-controller=\"job-status\"")
      expect(response.body).not_to include("Scene summary ready.")
    end

    it "redirects an unauthenticated request" do
      get status_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to have_http_status(:redirect)
    end

    it "redirects a non-member to root" do
      outsider = create(:user, :with_profile)
      sign_in(outsider)
      get status_game_scene_scene_summary_path(game, resolved_scene)
      expect(response).to redirect_to(root_path)
    end
  end
end
