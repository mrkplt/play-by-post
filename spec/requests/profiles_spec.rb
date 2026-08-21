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

    it "links the API tokens section to the Swagger UI docs, escaping Turbo" do
      sign_in(user)
      get profile_path
      expect(response.body).to include('href="/api-docs"')
      # Swagger UI is a mounted engine, not a Turbo page — the link must do a
      # full navigation or Turbo swaps its <body> into the app frame.
      expect(response.body).to include('data-turbo="false"')
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

  describe "POST /profile/toggle_ai_summaries_consent" do
    it "opts the user in and redirects with a notice" do
      sign_in(user)
      user.user_profile.update!(ai_summaries_consent: false)
      post toggle_ai_summaries_consent_profile_path
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq("AI scene summaries enabled for your games.")
      expect(user.user_profile.reload.ai_summaries_consent).to be(true)
    end

    it "opts the user back out and redirects with a notice" do
      sign_in(user)
      user.user_profile.update!(ai_summaries_consent: true)
      post toggle_ai_summaries_consent_profile_path
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq("AI scene summaries disabled for your games.")
      expect(user.user_profile.reload.ai_summaries_consent).to be(false)
    end

    it "unauthenticated user is redirected" do
      post toggle_ai_summaries_consent_profile_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /profile/update_ai_display_preference" do
    it "updates the preference to shown and redirects with a notice" do
      sign_in(user)
      post update_ai_display_preference_profile_path, params: { ai_display_preference: "shown" }
      expect(response).to redirect_to(profile_path)
      expect(flash[:notice]).to eq("AI display preference updated.")
      expect(user.user_profile.reload.ai_display_preference).to eq("shown")
    end

    it "updates the preference to hidden" do
      sign_in(user)
      post update_ai_display_preference_profile_path, params: { ai_display_preference: "hidden" }
      expect(user.user_profile.reload.ai_display_preference).to eq("hidden")
    end

    it "updates the preference to tagged" do
      sign_in(user)
      user.user_profile.update!(ai_display_preference: :shown)
      post update_ai_display_preference_profile_path, params: { ai_display_preference: "tagged" }
      expect(user.user_profile.reload.ai_display_preference).to eq("tagged")
    end

    it "rejects an unrecognized value" do
      sign_in(user)
      expect {
        post update_ai_display_preference_profile_path, params: { ai_display_preference: "invisible" }
      }.to raise_error(ArgumentError)
    end

    it "redirects with a bad-request alert when the param is missing" do
      sign_in(user)
      post update_ai_display_preference_profile_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Bad request.")
    end

    it "unauthenticated user is redirected" do
      post update_ai_display_preference_profile_path, params: { ai_display_preference: "shown" }
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
