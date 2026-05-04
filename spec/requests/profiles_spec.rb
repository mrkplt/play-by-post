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
    it "creates a new token and redirects" do
      sign_in(user)
      expect {
        post generate_rss_token_profile_path
      }.to change(RssToken, :count).by(1)
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to match(/generated/i)
    end

    it "rotates an existing token" do
      sign_in(user)
      existing = create(:rss_token, user: user)
      expect {
        post generate_rss_token_profile_path
      }.not_to change(RssToken, :count)
      expect(RssToken.find_by(id: existing.id)).to be_nil
      expect(user.reload.rss_token).to be_present
    end

    it "unauthenticated user is redirected" do
      post generate_rss_token_profile_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /profile/revoke_rss_token" do
    it "destroys an existing token and redirects" do
      sign_in(user)
      create(:rss_token, user: user)
      expect {
        delete revoke_rss_token_profile_path
      }.to change(RssToken, :count).by(-1)
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to match(/revoked/i)
    end

    it "does nothing when no token exists" do
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

    it "blocks a second all-games export within 24 hours" do
      sign_in(user)
      create(:game_export_request, :all_games, :recent, user: user)

      expect {
        post export_all_profile_path
      }.not_to change(GameExportRequest, :count)

      expect(response).to redirect_to(profile_path)
      expect(flash[:alert]).to match(/24 hours/i)
    end

    it "unauthenticated user is redirected" do
      post export_all_profile_path
      expect(response).to have_http_status(:redirect)
    end
  end
end
