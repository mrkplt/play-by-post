require "rails_helper"

RSpec.describe ActionMailbox::Ingresses::Resend::InboundEmailsController, type: :request do
  let(:webhook_secret) { "whsec_#{Base64.strict_encode64('supersecretkey1234567890abcdefgh')}" }
  let(:decoded_secret) { Base64.decode64(webhook_secret.delete_prefix("whsec_")) }

  # ActionMailbox enqueues a job when an InboundEmail is created; use the test
  # adapter so that job-queueing doesn't raise NotImplementedError.
  around do |example|
    original = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original
  end

  def raw_email_payload(from: "sender@example.com", to: "scene-1@inbound.example.com", subject: "Re: Scene")
    <<~MIME
      From: #{from}
      To: #{to}
      Subject: #{subject}
      Content-Type: text/plain; charset=UTF-8

      Hello from Resend inbound.
    MIME
  end

  def resend_payload(from: "sender@example.com", to: "scene-1@inbound.example.com")
    {
      type: "email.received",
      created_at: Time.now.iso8601,
      data: {
        email_id: "email_abc123",
        from: from,
        to: [ to ],
        subject: "Re: Scene",
        text: "Hello from Resend inbound.",
        html: "<p>Hello from Resend inbound.</p>",
        rawEmail: raw_email_payload(from: from, to: to)
      }
    }.to_json
  end

  def svix_headers(body:, secret:, svix_id: "msg_abc123")
    timestamp  = Time.now.to_i.to_s
    to_sign    = "#{svix_id}.#{timestamp}.#{body}"
    signature  = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, to_sign))

    {
      "svix-id"        => svix_id,
      "svix-timestamp" => timestamp,
      "svix-signature" => "v1,#{signature}"
    }
  end

  before do
    allow(Rails.application.credentials).to receive(:resend_webhook_secret).and_return(webhook_secret)
  end

  describe "POST /rails/action_mailbox/resend/inbound_emails" do
    context "with a valid signature and payload" do
      it "returns 200 and creates an InboundEmail" do
        body = resend_payload
        headers = svix_headers(body: body, secret: decoded_secret)

        expect {
          post rails_resend_inbound_emails_path,
            params: body,
            headers: headers.merge("Content-Type" => "application/json", "ACCEPT" => "application/json")
        }.to change(ActionMailbox::InboundEmail, :count).by(1)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with a missing signature header" do
      it "returns 401" do
        post rails_resend_inbound_emails_path,
          params: resend_payload,
          headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a tampered payload (signature mismatch)" do
      it "returns 401" do
        body = resend_payload
        headers = svix_headers(body: body, secret: decoded_secret)
        tampered = resend_payload(from: "attacker@evil.com")

        post rails_resend_inbound_emails_path,
          params: tampered,
          headers: headers.merge("Content-Type" => "application/json")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a stale timestamp (outside 5-minute window)" do
      it "returns 401" do
        body    = resend_payload
        old_ts  = (Time.now - 10.minutes).to_i.to_s
        to_sign = "msg_stale.#{old_ts}.#{body}"
        sig     = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", decoded_secret, to_sign))

        post rails_resend_inbound_emails_path,
          params: body,
          headers: {
            "svix-id"        => "msg_stale",
            "svix-timestamp" => old_ts,
            "svix-signature" => "v1,#{sig}",
            "Content-Type"   => "application/json"
          }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with malformed JSON (valid signature over the malformed body)" do
      it "returns 422" do
        body    = "not-json"
        headers = svix_headers(body: body, secret: decoded_secret)

        post rails_resend_inbound_emails_path,
          params: body,
          headers: headers.merge("Content-Type" => "application/json")

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when no webhook secret is configured" do
      before do
        allow(Rails.application.credentials).to receive(:resend_webhook_secret).and_return(nil)
      end

      it "returns 401" do
        body = resend_payload
        headers = svix_headers(body: body, secret: decoded_secret)

        post rails_resend_inbound_emails_path,
          params: body,
          headers: headers.merge("Content-Type" => "application/json")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a payload using fallback JSON fields (no rawEmail)" do
      it "returns 200 and creates an InboundEmail from constructed MIME" do
        payload = {
          type: "email.received",
          data: {
            email_id: "email_xyz",
            from: "sender@example.com",
            to: [ "scene-1@inbound.example.com" ],
            subject: "Re: Scene",
            text: "Plain text body",
            html: "<p>HTML body</p>"
          }
        }.to_json

        headers = svix_headers(body: payload, secret: decoded_secret)

        expect {
          post rails_resend_inbound_emails_path,
            params: payload,
            headers: headers.merge("Content-Type" => "application/json", "ACCEPT" => "application/json")
        }.to change(ActionMailbox::InboundEmail, :count).by(1)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
