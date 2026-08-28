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

    it "links the Your Games section to the Swagger UI docs, escaping Turbo" do
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

  describe "POST /profile/update_ai_display_preference" do
    let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it "updates the preference to shown and answers with a Turbo Stream, not a redirect" do
      sign_in(user)
      post update_ai_display_preference_profile_path, params: { ai_display_preference: "shown" }, headers: turbo_headers
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")

      # Both streams target the right id (a replace of the control and of the
      # toast layer). Nokogiri parses <template> content as a detached fragment,
      # so descendant selectors don't cross the boundary — assert the stream
      # targets and the rendered content separately.
      stream = Capybara.string(response.body)
      expect(stream).to have_css(
        %(turbo-stream[action="replace"][target="#{Ui::ProfileAiDisplayPreferenceControlComponent::CONTROL_ID}"])
      )
      expect(stream).to have_css(%(turbo-stream[action="replace"][target="toast_layer"]))

      # The control re-renders with the newly-chosen option pressed, and the
      # toast carries the notice. Content sits inside <template>, which Nokogiri
      # does not parse into the DOM tree, so assert on the raw markup.
      expect(response.body).to include(%(aria-pressed="true" type="submit">Shown))
      expect(response.body).to include(%(<span class="toast__message">AI display preference updated.</span>))
      expect(user.user_profile.reload.ai_display_preference).to eq("shown")
    end

    it "does not persist the notice into the next full page load" do
      sign_in(user)
      post update_ai_display_preference_profile_path, params: { ai_display_preference: "shown" }, headers: turbo_headers

      # flash.now, so it is consumed by this render and gone on the next request.
      get profile_path
      expect(response.body).not_to include("AI display preference updated.")
    end

    it "updates the preference to hidden" do
      sign_in(user)
      post update_ai_display_preference_profile_path, params: { ai_display_preference: "hidden" }, headers: turbo_headers
      expect(user.user_profile.reload.ai_display_preference).to eq("hidden")
    end

    it "updates the preference to tagged" do
      sign_in(user)
      user.user_profile.update!(ai_display_preference: :shown)
      post update_ai_display_preference_profile_path, params: { ai_display_preference: "tagged" }, headers: turbo_headers
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

      # In place: a toast, no full profile reload.
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("toast_layer")
      expect(response.body).to match(/export requested/i)

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

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/export requested/i)
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
