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
          head(process_webhook)
        end

        private

        # A single status symbol, so #create has exactly one place that renders
        # a response instead of a `head` call scattered across every failure
        # branch.
        sig { returns(Symbol) }
        def process_webhook
          email_id = @payload.dig("data", "email_id")
          return :unprocessable_entity unless email_id

          ingest_email(email_id)
        end

        sig { params(email_id: String).returns(Symbol) }
        def ingest_email(email_id)
          create_inbound_email(email_id)
          :ok
        rescue StandardError => error
          Rails.logger.error("Resend inbound email processing failed: #{error.message}")
          :unprocessable_entity
        end

        sig { params(email_id: String).void }
        def create_inbound_email(email_id)
          raw_mime = InboundMailBuilder.call(::Resend::Emails::Receiving.get(email_id))
          ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_mime)
        end

        sig { void }
        def verify_signature
          ::Resend::Webhooks.verify(
            payload:        request.raw_post,
            headers:        svix_headers,
            webhook_secret: Rails.application.credentials.resend_webhook_secret
          )
        rescue StandardError => error
          Rails.logger.warn("Resend webhook verification failed: #{error.message}")
          head :unauthorized
        end

        sig { returns(T::Hash[Symbol, T.nilable(String)]) }
        def svix_headers
          %w[svix-id svix-timestamp svix-signature].to_h do |name|
            [ name.tr("-", "_").to_sym, request.headers[name] ]
          end
        end

        sig { void }
        def parse_payload
          @payload = JSON.parse(request.raw_post)
        rescue JSON::ParserError
          head :unprocessable_entity
        end
      end
    end
  end
end
