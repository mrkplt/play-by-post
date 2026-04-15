# typed: true

module ActionMailbox
  module Ingresses
    module Resend
      # Receives inbound email webhooks from Resend and feeds them into ActionMailbox.
      #
      # Resend delivers inbound emails as signed JSON webhook POSTs. The payload
      # includes the raw MIME message in +data.raw_email+. Authentication uses the
      # Svix webhook-signing standard: the controller verifies an HMAC-SHA256
      # signature carried in three HTTP headers (svix-id, svix-timestamp,
      # svix-signature) against the +resend_webhook_secret+ credential.
      #
      # Credentials expected in Rails credentials:
      #   resend_webhook_secret: "whsec_<base64-value>"  # signing secret from Resend dashboard
      #
      # The corresponding webhook URL to register in the Resend dashboard is:
      #   https://<your-host>/rails/action_mailbox/resend/inbound_emails
      class InboundEmailsController < ActionController::Base
        extend T::Sig

        TIMESTAMP_TOLERANCE_SECONDS = 300
        private_constant :TIMESTAMP_TOLERANCE_SECONDS

        before_action :verify_signature
        before_action :parse_payload

        sig { void }
        def create
          raw = @payload.dig("data", "rawEmail") || @payload.dig("data", "raw_email") || build_raw_email
          ActionMailbox::InboundEmail.create_and_extract_message_id!(raw)
          head :ok
        rescue StandardError => e
          Rails.logger.error("Resend inbound email processing failed: #{e.message}")
          head :unprocessable_entity
        end

        private

        sig { void }
        def verify_signature
          svix_id        = request.headers["svix-id"]
          svix_timestamp = request.headers["svix-timestamp"]
          svix_signature = request.headers["svix-signature"]

          unless svix_id && svix_timestamp && svix_signature
            return head :unauthorized
          end

          # Reject replayed webhooks outside the tolerance window.
          ts = svix_timestamp.to_i
          if (Time.now.to_i - ts).abs > TIMESTAMP_TOLERANCE_SECONDS
            return head :unauthorized
          end

          secret = Rails.application.credentials.resend_webhook_secret
          unless secret
            Rails.logger.warn("resend_webhook_secret is not configured; rejecting inbound webhook")
            return head :unauthorized
          end

          to_sign        = "#{svix_id}.#{svix_timestamp}.#{request.raw_post}"
          decoded_secret = Base64.decode64(secret.delete_prefix("whsec_"))
          computed_b64   = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", decoded_secret, to_sign))

          # The header may carry multiple space-separated "v1,<base64>" entries.
          valid = svix_signature.split(" ").any? do |entry|
            candidate = entry.split(",", 2).last
            ActiveSupport::SecurityUtils.secure_compare(candidate, computed_b64)
          end

          head :unauthorized unless valid
        end

        sig { void }
        def parse_payload
          @payload = JSON.parse(request.raw_post)
        rescue JSON::ParserError
          head :unprocessable_entity
        end

        # Fall back to constructing a minimal MIME message when Resend does not
        # include a raw_email field (e.g. older API versions or partial payloads).
        sig { returns(String) }
        def build_raw_email
          data = @payload.fetch("data", {})

          mail = Mail.new do
            from    data["from"]
            to      Array(data["to"]).join(", ")
            subject data["subject"]
          end

          html_body = data["html"]
          text_body = data["text"]

          if html_body && text_body
            mail.text_part { body text_body }
            mail.html_part do
              content_type "text/html; charset=UTF-8"
              body html_body
            end
          elsif html_body
            mail.content_type = "text/html; charset=UTF-8"
            mail.body = html_body
          else
            mail.body = text_body.to_s
          end

          mail.to_s
        end
      end
    end
  end
end
