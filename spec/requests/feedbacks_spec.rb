require "rails_helper"

RSpec.describe FeedbacksController, type: :request do
  let(:user) { create(:user, :with_profile) }

  describe "POST /feedbacks" do
    it "unauthenticated user is redirected" do
      post feedbacks_path, params: { feedback: { body: "Hi", url: "https://example.com/x" } }
      expect(response).to have_http_status(:redirect)
      expect(Feedback.count).to eq(0)
    end

    context "when signed in" do
      before { sign_in(user) }

      it "saves the feedback with the submitter and url, then redirects back" do
        expect {
          post feedbacks_path,
            params: { feedback: { body: "The composer is great", url: "https://example.com/games/7" } },
            headers: { "HTTP_REFERER" => "http://www.example.com/games/7" }
        }.to change(Feedback, :count).by(1)

        feedback = Feedback.last
        expect(feedback.user).to eq(user)
        expect(feedback.body).to eq("The composer is great")
        expect(feedback.url).to eq("https://example.com/games/7")
        expect(response).to redirect_to("http://www.example.com/games/7")
        expect(flash[:notice]).to eq("Thanks for your feedback!")
      end

      it "falls back to root_path when there is no referer" do
        post feedbacks_path, params: { feedback: { body: "No referer", url: "" } }
        expect(response).to redirect_to(root_path)
      end

      it "does not save a blank body and reports an error" do
        expect {
          post feedbacks_path,
            params: { feedback: { body: "", url: "https://example.com/x" } },
            headers: { "HTTP_REFERER" => "http://www.example.com/x" }
        }.not_to change(Feedback, :count)

        expect(response).to redirect_to("http://www.example.com/x")
        expect(flash[:alert]).to eq("Feedback can't be blank.")
      end

      it "falls back to root_path on a blank body when there is no referer" do
        post feedbacks_path, params: { feedback: { body: "", url: "" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Feedback can't be blank.")
      end

      it "requires the feedback param" do
        post feedbacks_path, params: {}
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Bad request.")
      end
    end
  end
end
