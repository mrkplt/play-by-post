require "rails_helper"

RSpec.describe Webhooks::DeployController, type: :request do
  let(:secret) { "supersecretdeploytoken1234567890" }

  around do |example|
    original = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original
  end

  before do
    allow(Rails.application.credentials).to receive(:deploy_webhook_secret).and_return(secret)
  end

  describe "POST /webhooks/deploy" do
    context "with a valid bearer secret" do
      it "returns 202 and enqueues a CoolifyDeployJob" do
        expect {
          post deploy_webhook_path, headers: { "Authorization" => "Bearer #{secret}" }
        }.to have_enqueued_job(CoolifyDeployJob)

        expect(response).to have_http_status(:accepted)
      end
    end

    context "with an incorrect bearer secret" do
      it "returns 401 and does not enqueue a job" do
        expect {
          post deploy_webhook_path, headers: { "Authorization" => "Bearer wrong-secret" }
        }.not_to have_enqueued_job(CoolifyDeployJob)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a missing Authorization header" do
      it "returns 401" do
        post deploy_webhook_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when no deploy secret is configured" do
      before do
        allow(Rails.application.credentials).to receive(:deploy_webhook_secret).and_return(nil)
      end

      it "returns 401 even when the header matches an empty secret" do
        post deploy_webhook_path, headers: { "Authorization" => "Bearer " }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
