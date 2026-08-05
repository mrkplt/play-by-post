require "rails_helper"

RSpec.describe Users::SessionsController, type: :request do
  describe "POST /users/sign_in" do
    context "with blank email" do
      it "renders :new with unprocessable_content and the prompt" do
        post user_session_path, params: { user: { email: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Please enter an email address")
      end

      it "shows the sign-in form (not the confirmation) when no email param is sent" do
        post user_session_path, params: {}
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Sign in")
        expect(response.body).not_to include("Check your email")
      end
    end

    context "with valid email for a new user" do
      it "creates the user and renders the confirmation" do
        expect {
          post user_session_path, params: { user: { email: "newuser@example.com" } }
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Check your email")
      end

      it "seeds the profile display name from the email local part" do
        post user_session_path, params: { user: { email: "alice@example.com" } }
        expect(User.find_by(email: "alice@example.com").user_profile.display_name).to eq("alice")
      end

      it "normalizes the email by stripping and downcasing before lookup" do
        post user_session_path, params: { user: { email: "  Bob@Example.COM  " } }
        expect(User.find_by(email: "bob@example.com")).to be_present
      end

      it "accepts a top-level email param as a fallback" do
        expect {
          post user_session_path, params: { email: "toplevel@example.com" }
        }.to change { User.exists?(email: "toplevel@example.com") }.to(true)
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

      it "does not recreate or alter the existing profile" do
        existing_user.user_profile.update!(display_name: "Kept Name")
        post user_session_path, params: { user: { email: "existing@example.com" } }
        expect(existing_user.user_profile.reload.display_name).to eq("Kept Name")
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

    it "issues a persistent remember-me cookie when following the emailed link" do
      # Full chain: POST sends the link with remember_me: true (SessionsController),
      # and clicking that exact link must set the 30-day remember cookie.
      post user_session_path, params: { user: { email: user.email } }
      href = ActionMailer::Base.deliveries.last.body.encoded[/href="([^"]+)"/, 1]
      link = CGI.unescapeHTML(href).sub(%r{\Ahttps?://[^/]+}, "")

      get link

      expect(response.cookies["remember_user_token"]).to be_present
    end

    it "updates last_login_at via Warden after_set_user callback" do
      user.user_profile.update!(last_login_at: 1.hour.ago)
      token = Devise::Passwordless::SignedGlobalIDTokenizer.encode(user)
      expect {
        get user_magic_link_path, params: { user: { email: user.email, token: token } }
      }.to change { user.user_profile.reload.last_login_at }
    end

    it "still signs in the user within the one-day validity window" do
      token = Timecop.freeze { Devise::Passwordless::SignedGlobalIDTokenizer.encode(user) }
      Timecop.travel(23.hours.from_now) do
        get user_magic_link_path, params: { user: { email: user.email, token: token } }
      end
      expect(response).to redirect_to(root_path)
    end

    it "rejects a magic link older than one day" do
      token = Timecop.freeze { Devise::Passwordless::SignedGlobalIDTokenizer.encode(user) }
      Timecop.travel(25.hours.from_now) do
        get user_magic_link_path, params: { user: { email: user.email, token: token } }
      end
      expect(response).not_to redirect_to(root_path)
    end
  end
end
