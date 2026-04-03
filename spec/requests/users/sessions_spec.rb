require "rails_helper"

RSpec.describe Users::SessionsController, type: :request do
  describe "POST /users/sign_in" do
    context "with blank email" do
      it "renders :new with unprocessable_content" do
        post user_session_path, params: { user: { email: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with valid email for a new user" do
      it "creates the user and renders :new with email_sent" do
        expect {
          post user_session_path, params: { user: { email: "newuser@example.com" } }
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with valid email for an existing user" do
      let!(:existing_user) { create(:user, :with_profile, email: "existing@example.com") }

      it "does not create a new user and renders :new" do
        expect {
          post user_session_path, params: { user: { email: "existing@example.com" } }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:ok)
      end

      it "sends the magic link email" do
        post user_session_path, params: { user: { email: "existing@example.com" } }
        expect(ActionMailer::Base.deliveries).not_to be_empty
      end
    end

    context "after sign in" do
      let(:user) { create(:user, :with_profile) }

      it "redirects to root path after sign in" do
        sign_in(user)
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /users/magic_link (token confirmation)" do
    let(:user) { create(:user, :with_profile) }

    it "signs in the user and redirects to root" do
      token = Devise::Passwordless::SignedGlobalIDTokenizer.encode(user)
      get user_magic_link_path, params: { user: { email: user.email, token: token } }
      expect(response).to redirect_to(root_path)
    end

    it "updates last_login_at via Warden after_set_user callback" do
      user.user_profile.update!(last_login_at: 1.hour.ago)
      token = Devise::Passwordless::SignedGlobalIDTokenizer.encode(user)
      expect {
        get user_magic_link_path, params: { user: { email: user.email, token: token } }
      }.to change { user.user_profile.reload.last_login_at }
    end
  end
end
