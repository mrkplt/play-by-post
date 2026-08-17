# typed: true

class ApplicationMailer < ActionMailer::Base
  default from: "noreply@notifications.flailwhale.com"
  layout "mailer"

  # Mailer views do not inherit app/helpers automatically; make the palette-
  # sourced inline-style helpers available to every mailer template.
  helper MailStylesHelper
end
