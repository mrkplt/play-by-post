# typed: true

class ApplicationMailer < ActionMailer::Base
  default from: "noreply@notifications.flailwhale.com"
  layout "mailer"
end
