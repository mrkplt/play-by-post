require "rails_helper"

# Exercises the TurnstileVerification controller module through the two forms it
# guards. Turnstile is disabled in the test env by default, so each context that
# needs enforcement force-enables it and stubs the verifier at its boundary.
RSpec.describe "Turnstile verification", type: :request do
  describe "magic-link sign-in (Users::SessionsController#create)" do
    context "when Turnstile is disabled (default test env)" do
      it "does not require a token" do
        post user_session_path, params: { user: { email: "nobody@example.com" } }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Check your email")
      end
    end

    context "when Turnstile is enabled" do
      before { allow(Turnstile).to receive(:enabled?).and_return(true) }

      it "proceeds when the token verifies" do
        allow(TurnstileVerifier).to receive(:verify).and_return(true)
        post user_session_path, params: { user: { email: "ok@example.com" }, "cf-turnstile-response" => "good" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Check your email")
      end

      it "re-renders the sign-in form with an error when the token fails" do
        allow(TurnstileVerifier).to receive(:verify).and_return(false)
        expect {
          post user_session_path, params: { user: { email: "bot@example.com" }, "cf-turnstile-response" => "bad" }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Sign in")
        expect(response.body).to include("verification challenge")
      end

      it "passes the submitted token and remote ip to the verifier" do
        expect(TurnstileVerifier).to receive(:verify)
          .with(hash_including(token: "tok123")).and_return(true)
        post user_session_path, params: { user: { email: "ok@example.com" }, "cf-turnstile-response" => "tok123" }
      end
    end
  end

  describe "feedback (FeedbackController#create)" do
    let(:user) { create(:user, :with_profile) }

    before { sign_in(user) }

    context "when Turnstile is disabled (default test env)" do
      it "does not require a token" do
        expect {
          post feedback_path, params: { feedback: { body: "great app", url: "/games" } }
        }.to change(user.feedback, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context "when Turnstile is enabled" do
      before { allow(Turnstile).to receive(:enabled?).and_return(true) }

      it "proceeds when the token verifies" do
        allow(TurnstileVerifier).to receive(:verify).and_return(true)
        expect {
          post feedback_path, params: { feedback: { body: "great app", url: "/games" }, "cf-turnstile-response" => "good" }
        }.to change(user.feedback, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "returns 403 without saving when the token fails" do
        allow(TurnstileVerifier).to receive(:verify).and_return(false)
        expect {
          post feedback_path, params: { feedback: { body: "spam", url: "/" }, "cf-turnstile-response" => "bad" }
        }.not_to change(Feedback, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
