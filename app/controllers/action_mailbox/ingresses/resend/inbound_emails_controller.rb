# typed: true

module ActionMailbox
  module Ingresses
    module Resend
      # Receives inbound email webhooks from Resend and feeds them into ActionMailbox.
      #
      # Resend delivers inbound email events as signed JSON webhook POSTs. The initial
      # payload carries metadata only (from, to, subject, email_id). A follow-up call to
      # +Resend::Emails::Receiving.get+ retrieves the full message body, which is then
      # assembled into a MIME message and handed to ActionMailbox.
      #
      # Authentication uses the Svix webhook-signing standard. The gem's built-in
      # +Resend::Webhooks.verify+ handles HMAC-SHA256 verification against the
      # +resend_webhook_secret+ credential.
      #
      # Credentials required:
      #   resend_webhook_secret: "whsec_<base64-value>"  # from the Resend dashboard
      #
      # Register this URL in the Resend dashboard as the inbound webhook endpoint:
      #   https://<your-host>/rails/action_mailbox/resend/inbound_emails
      class InboundEmailsController < ActionMailbox::BaseController
        extend T::Sig

        before_action :verify_signature
        before_action :parse_payload

        sig { void }
        def create
          email_id = @payload.dig("data", "email_id")
          return head :unprocessable_entity unless email_id

          email_data = ::Resend::Emails::Receiving.get(email_id)
          raw_mime   = build_raw_email(email_data)

          ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_mime)
          head :ok
        rescue StandardError => e
          Rails.logger.error("Resend inbound email processing failed: #{e.message}")
          head :unprocessable_entity
        end

        private

        sig { void }
        def verify_signature
          ::Resend::Webhooks.verify(
            payload:        request.raw_post,
            headers:        {
              svix_id:        request.headers["svix-id"],
              svix_timestamp: request.headers["svix-timestamp"],
              svix_signature: request.headers["svix-signature"]
            },
            webhook_secret: Rails.application.credentials.resend_webhook_secret
          )
        rescue StandardError => e
          Rails.logger.warn("Resend webhook verification failed: #{e.message}")
          head :unauthorized
        end

        sig { void }
        def parse_payload
          @payload = JSON.parse(request.raw_post)
        rescue JSON::ParserError
          head :unprocessable_entity
        end

        # Assembles a minimal RFC 2822 MIME message from the Resend email object
        # returned by +Resend::Emails::Receiving.get+.
        sig { params(data: T::Hash[T.untyped, T.untyped]).returns(String) }
        def build_raw_email(data)
          mail         = Mail.new
          mail.from    = data["from"].to_s
          mail.to      = Array(data["to"]).join(", ")
          mail.subject = data["subject"].to_s

          html_body = data["html"]
          text_body = data["text"]

          if html_body && text_body
            text_part         = Mail::Part.new
            text_part.body    = text_body
            mail.text_part    = text_part

            html_part              = Mail::Part.new
            html_part.content_type = "text/html; charset=UTF-8"
            html_part.body         = html_body
            mail.html_part         = html_part
          elsif html_body
            mail.content_type = "text/html; charset=UTF-8"
            mail.body         = html_body
          else
            mail.body = text_body.to_s
          end

          mail.to_s
        end
      end
    end
  end
end
