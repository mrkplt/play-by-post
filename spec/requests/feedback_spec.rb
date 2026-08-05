require "rails_helper"

RSpec.describe FeedbackController, type: :request do
  let(:user) { create(:user, :with_profile) }

  describe "POST /feedback" do
    it "unauthenticated user is redirected" do
      post feedback_path, params: { feedback: { body: "Hi", url: "https://example.com/x" } }
      expect(response).to have_http_status(:redirect)
      expect(Feedback.count).to eq(0)
    end

    context "when signed in" do
      before { sign_in(user) }

      it "saves the feedback with the submitter and url, answering 201 and staying put" do
        expect {
          post feedback_path,
            params: { feedback: { body: "The composer is great", url: "https://example.com/games/7" } }
        }.to change(Feedback, :count).by(1)

        feedback = Feedback.last
        expect(feedback.user).to eq(user)
        expect(feedback.body).to eq("The composer is great")
        expect(feedback.url).to eq("https://example.com/games/7")
        expect(response).to have_http_status(:created)
      end

      it "rejects a blank body with an unprocessable status and saves nothing" do
        expect {
          post feedback_path, params: { feedback: { body: "", url: "https://example.com/x" } }
        }.not_to change(Feedback, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "requires the feedback param" do
        post feedback_path, params: {}
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Bad request.")
      end
    end
  end
end
