# typed: true

Rails.application.config.after_initialize do
  Rails.application.config.action_mailbox.ingress_password = Rails.application.credentials.inbound_email_password
end
