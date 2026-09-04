require "rails_helper"

RSpec.describe AiControlPlaneController, type: :request do
  let(:user) { create(:user, :with_profile) }

  describe "GET /ai-control-plane" do
    it "renders ok for an authenticated user" do
      sign_in(user)
      get ai_control_plane_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the explainer sections" do
      sign_in(user)
      get ai_control_plane_path
      expect(response.body).to include("Bring your own key")
      expect(response.body).to include("Two consent gates")
      expect(response.body).to include("Provenance is always recorded")
    end

    it "renders the universal header nav affordances" do
      sign_in(user)
      get ai_control_plane_path
      expect_hamburger_present
    end

    it "redirects an unauthenticated user" do
      get ai_control_plane_path
      expect(response).to have_http_status(:redirect)
    end
  end
end
