require "rails_helper"

RSpec.describe ActionMailbox::Ingresses::Resend::InboundEmailsController, type: :request do
  # whsec_-prefixed base64 secret, matching Resend's format.
  let(:webhook_secret) { "whsec_#{Base64.strict_encode64('supersecretkey1234567890abcdefgh')}" }

  # ActionMailbox enqueues a job when an InboundEmail is created; use the test
  # adapter so job-queueing doesn't raise NotImplementedError.
  around do |example|
    original = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original
  end

  # Fake full-email API response returned by Resend::Emails::Receiving.get.
  let(:email_api_response) do
    {
      "from"    => "sender@example.com",
      "to"      => [ "scene-1@inbound.example.com" ],
      "subject" => "Re: Scene",
      "text"    => "Hello from Resend inbound.",
      "html"    => "<p>Hello from Resend inbound.</p>"
    }
  end

  before do
    allow(Rails.application.credentials).to receive(:resend_webhook_secret).and_return(webhook_secret)
    allow(::Resend::Emails::Receiving).to receive(:get).and_return(email_api_response)
  end

  # Builds a minimal Resend inbound webhook payload (metadata only — no body).
  def resend_webhook_payload(email_id: "email_abc123", from: "sender@example.com", to: "scene-1@inbound.example.com")
    {
      type: "email.received",
      created_at: Time.now.iso8601,
      data: {
        email_id: email_id,
        from: from,
        to: [ to ],
        subject: "Re: Scene"
      }
    }.to_json
  end

  # Generates valid Svix headers for a given raw body and secret, mirroring
  # exactly what Resend::Webhooks.verify expects on the receiving end.
  def svix_headers(body:, secret:, svix_id: "msg_abc123")
    timestamp      = Time.now.to_i.to_s
    decoded_secret = Base64.strict_decode64(secret.delete_prefix("whsec_"))
    to_sign        = "#{svix_id}.#{timestamp}.#{body}"
    signature      = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", decoded_secret, to_sign))

    {
      "svix-id"        => svix_id,
      "svix-timestamp" => timestamp,
      "svix-signature" => "v1,#{signature}"
    }
  end

  # Posts a signed webhook and returns the parsed Mail object from the stored
  # InboundEmail source — used by MIME-content assertions below.
  def post_signed_webhook(api_response: email_api_response, **payload_opts)
    allow(::Resend::Emails::Receiving).to receive(:get).and_return(api_response)
    body    = resend_webhook_payload(**payload_opts)
    headers = svix_headers(body: body, secret: webhook_secret)
    post rails_resend_inbound_emails_path,
      params: body,
      headers: headers.merge("Content-Type" => "application/json")
    Mail.new(ActionMailbox::InboundEmail.last.source)
  end

  describe "POST /rails/action_mailbox/resend/inbound_emails" do
    context "with a valid signature and payload" do
      it "returns 200 and creates an InboundEmail" do
        body = resend_webhook_payload
        headers = svix_headers(body: body, secret: webhook_secret)

        expect {
          post rails_resend_inbound_emails_path,
            params: body,
            headers: headers.merge("Content-Type" => "application/json")
        }.to change(ActionMailbox::InboundEmail, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it "fetches the full email body from the Resend API using the email_id" do
        body = resend_webhook_payload(email_id: "email_xyz999")
        headers = svix_headers(body: body, secret: webhook_secret)

        post rails_resend_inbound_emails_path,
          params: body,
          headers: headers.merge("Content-Type" => "application/json")

        expect(::Resend::Emails::Receiving).to have_received(:get).with("email_xyz999")
      end
    end

    context "with a missing signature header" do
      it "returns 401" do
        post rails_resend_inbound_emails_path,
          params: resend_webhook_payload,
          headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a tampered payload (signature mismatch)" do
      it "returns 401" do
        original = resend_webhook_payload
        headers  = svix_headers(body: original, secret: webhook_secret)
        tampered = resend_webhook_payload(from: "attacker@evil.com")

        post rails_resend_inbound_emails_path,
          params: tampered,
          headers: headers.merge("Content-Type" => "application/json")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a stale timestamp (outside 5-minute window)" do
      it "returns 401" do
        body      = resend_webhook_payload
        old_ts    = (Time.now - 10.minutes).to_i.to_s
        dec_sec   = Base64.strict_decode64(webhook_secret.delete_prefix("whsec_"))
        sig       = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", dec_sec, "msg_stale.#{old_ts}.#{body}"))

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

    context "with a payload missing email_id" do
      it "returns 422" do
        body = { type: "email.received", data: {} }.to_json
        headers = svix_headers(body: body, secret: webhook_secret)

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
        body = resend_webhook_payload
        headers = svix_headers(body: body, secret: webhook_secret)

        post rails_resend_inbound_emails_path,
          params: body,
          headers: headers.merge("Content-Type" => "application/json")

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "MIME message construction" do
    context "when the API response has both html and text" do
      let(:api_response) do
        {
          "from"    => "author@example.com",
          "to"      => [ "scene-42@inbound.example.com" ],
          "subject" => "The Subject Line",
          "text"    => "Plain text body",
          "html"    => "<p>HTML body</p>"
        }
      end

      subject(:mail) { post_signed_webhook(api_response: api_response) }

      it "sets the from address" do
        expect(mail.from).to include("author@example.com")
      end

      it "sets the to address" do
        expect(mail.to).to include("scene-42@inbound.example.com")
      end

      it "sets the subject" do
        expect(mail.subject).to eq("The Subject Line")
      end

      it "includes a text part" do
        expect(mail.text_part.body.to_s).to include("Plain text body")
      end

      it "includes an html part" do
        expect(mail.html_part.body.to_s).to include("<p>HTML body</p>")
      end
    end

    context "when the API response has only html (no text)" do
      let(:api_response) do
        {
          "from"    => "author@example.com",
          "to"      => [ "scene-42@inbound.example.com" ],
          "subject" => "HTML Only",
          "text"    => nil,
          "html"    => "<p>HTML only body</p>"
        }
      end

      subject(:mail) { post_signed_webhook(api_response: api_response) }

      it "sets text/html content type" do
        expect(mail.content_type).to include("text/html")
      end

      it "includes the HTML body" do
        expect(mail.body.to_s).to include("<p>HTML only body</p>")
      end
    end

    context "when the API response has only text (no html)" do
      let(:api_response) do
        {
          "from"    => "author@example.com",
          "to"      => [ "scene-42@inbound.example.com" ],
          "subject" => "Text Only",
          "text"    => "Plain text only body",
          "html"    => nil
        }
      end

      subject(:mail) { post_signed_webhook(api_response: api_response) }

      it "includes the text body" do
        expect(mail.body.to_s).to include("Plain text only body")
      end
    end

    context "when the API response has neither text nor html" do
      let(:api_response) do
        {
          "from"    => "author@example.com",
          "to"      => [ "scene-42@inbound.example.com" ],
          "subject" => "Empty",
          "text"    => nil,
          "html"    => nil
        }
      end

      it "creates an InboundEmail with an empty body" do
        expect {
          post_signed_webhook(api_response: api_response)
        }.to change(ActionMailbox::InboundEmail, :count).by(1)
      end
    end
  end
end
