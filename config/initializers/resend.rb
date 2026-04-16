# typed: true

# Configure the Resend API key for outbound email delivery.
# The key is set here so it is available to both ActionMailer (delivery_method :resend)
# and the custom inbound webhook controller.
if (api_key = Rails.application.credentials.resend_api_key)
  Resend.api_key = api_key
end
