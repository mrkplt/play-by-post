require "rails_helper"

RSpec.describe ProfilesController, type: :request do
  let(:user) { create(:user, :with_profile) }

  describe "GET /profile" do
    it "renders ok for authenticated user" do
      sign_in(user)
      get profile_path
      expect(response).to have_http_status(:ok)
    end

    it "unauthenticated user is redirected" do
      get profile_path
      expect(response).to have_http_status(:redirect)
    end

    it "renders the universal header nav affordances with no breadcrumb" do
      sign_in(user)
      get profile_path
      expect_hamburger_present
    end
  end

  describe "GET /profile/edit" do
    it "renders ok for authenticated user" do
      sign_in(user)
      get edit_profile_path
      expect(response).to have_http_status(:ok)
    end

    it "unauthenticated user is redirected" do
      get edit_profile_path
      expect(response).to have_http_status(:redirect)
    end

    it "renders the universal header nav affordances with no breadcrumb" do
      sign_in(user)
      get edit_profile_path
      expect_hamburger_present
    end

    it "renders visible text on the primary and cancel page-action buttons" do
      sign_in(user)
      get edit_profile_path
      expect(response.body).to include(">Save<")
      expect(response.body).to include(">Cancel<")
    end
  end

  describe "PATCH /profile" do
    it "updates display_name and redirects" do
      sign_in(user)
      patch profile_path, params: { user_profile: { display_name: "New Name" } }
      expect(response).to redirect_to(root_path)
      expect(user.user_profile.reload.display_name).to eq("New Name")
    end

    it "renders :edit with unprocessable_content when save fails" do
      sign_in(user)
      allow_any_instance_of(UserProfile).to receive(:save).and_return(false)
      patch profile_path, params: { user_profile: { display_name: "Something" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "unauthenticated user is redirected" do
      patch profile_path, params: { user_profile: { display_name: "Hacked" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /profile/toggle_hide_ooc" do
    it "toggles hide_ooc and returns ok" do
      sign_in(user)
      initial = user.user_profile.hide_ooc
      post toggle_hide_ooc_profile_path
      expect(response).to have_http_status(:ok)
      expect(user.user_profile.reload.hide_ooc).to eq(!initial)
    end

    it "unauthenticated user is redirected" do
      post toggle_hide_ooc_profile_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /profile/generate_rss_token" do
    it "creates an account-level token when no game_id is given" do
      sign_in(user)
      expect {
        post generate_rss_token_profile_path
      }.to change(RssToken.account_level, :count).by(1)
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to match(/generated/i)
    end

    it "creates a game-scoped token for a member game" do
      game = create(:game)
      create(:game_member, game: game, user: user)
      sign_in(user)
      expect {
        post generate_rss_token_profile_path, params: { game_id: game.id }
      }.to change { RssToken.where(user: user, game: game).count }.by(1)
    end

    it "rotates the existing token for that scope only" do
      game = create(:game)
      create(:game_member, game: game, user: user)
      account_token = create(:rss_token, user: user, game: nil)
      old_game_token = create(:rss_token, user: user, game: game)
      sign_in(user)

      expect {
        post generate_rss_token_profile_path, params: { game_id: game.id }
      }.not_to change(RssToken, :count)

      expect(RssToken.find_by(id: old_game_token.id)).to be_nil
      expect(RssToken.find_by(id: account_token.id)).to be_present
    end

    it "refuses a game the user is not a member of" do
      game = create(:game)
      sign_in(user)
      expect {
        post generate_rss_token_profile_path, params: { game_id: game.id }
      }.not_to change(RssToken, :count)
      expect(flash[:alert]).to match(/not a member/i)
    end

    it "unauthenticated user is redirected" do
      post generate_rss_token_profile_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /profile/revoke_rss_token" do
    it "destroys the account-level token and redirects" do
      sign_in(user)
      create(:rss_token, user: user, game: nil)
      expect {
        delete revoke_rss_token_profile_path
      }.to change(RssToken.account_level, :count).by(-1)
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to match(/revoked/i)
    end

    it "destroys only the named game's token" do
      game = create(:game)
      create(:game_member, game: game, user: user)
      create(:rss_token, user: user, game: nil)
      create(:rss_token, user: user, game: game)
      sign_in(user)

      expect {
        delete revoke_rss_token_profile_path, params: { game_id: game.id }
      }.to change { RssToken.where(user: user, game: game).count }.by(-1)

      expect(RssToken.account_level.where(user: user)).to be_present
    end

    it "refuses a game the user is not a member of and revokes nothing" do
      game = create(:game)
      create(:rss_token, user: user, game: nil)
      sign_in(user)

      expect {
        delete revoke_rss_token_profile_path, params: { game_id: game.id }
      }.not_to change(RssToken, :count)

      expect(flash[:alert]).to match(/not a member/i)
    end

    it "does nothing when no token exists for the scope" do
      sign_in(user)
      expect {
        delete revoke_rss_token_profile_path
      }.not_to change(RssToken, :count)
      expect(response).to redirect_to(profile_path)
    end

    it "unauthenticated user is redirected" do
      delete revoke_rss_token_profile_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /profile/export_all" do
    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "creates an all-games export request and enqueues the job" do
      sign_in(user)
      expect {
        post export_all_profile_path
      }.to change(GameExportRequest, :count).by(1)
        .and have_enqueued_job(ExportJob)

      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to match(/export requested/i)

      request = GameExportRequest.last
      expect(request.user).to eq(user)
      expect(request.game).to be_nil
    end

    it "resends the existing link instead of reprocessing when a valid all-games receipt exists" do
      sign_in(user)
      receipt = create(:game_export_request, :all_games, user: user, succeeded_at: 1.hour.ago)
      receipt.archive.attach(io: StringIO.new("zip"), filename: "all.zip", content_type: "application/zip")

      expect {
        post export_all_profile_path
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      expect {
        post export_all_profile_path
      }.not_to have_enqueued_job(ExportJob)
      expect(GameExportRequest.where(game: nil).count).to eq(1)

      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to match(/export requested/i)
    end

    it "processes a new all-games export when a recent request never succeeded" do
      sign_in(user)
      create(:game_export_request, :all_games, :recent, user: user)

      expect {
        post export_all_profile_path
      }.to change(GameExportRequest, :count).by(1)
        .and have_enqueued_job(ExportJob)
    end

    it "unauthenticated user is redirected" do
      post export_all_profile_path
      expect(response).to have_http_status(:redirect)
    end
  end
end
