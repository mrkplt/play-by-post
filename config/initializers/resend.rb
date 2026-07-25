# typed: true

# Configure the Resend API key for outbound email delivery.
# The key is set here so it is available to both ActionMailer (delivery_method :resend)
# and the custom inbound webhook controller.
#
# Credentials are unavailable during image builds: config/credentials/*.key is
# gitignored, so `assets:precompile` boots the app without a decryption key.
# Assets do not need the Resend key, so treat it as absent rather than failing
# the build. Runtime supplies the key and this initializer then behaves normally.
api_key =
  begin
    Rails.application.credentials.resend_api_key
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    Rails.logger.warn("Resend: credentials unavailable, skipping API key setup")
    nil
  end

Resend.api_key = api_key if api_key
