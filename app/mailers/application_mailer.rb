# typed: true

class ApplicationMailer < ActionMailer::Base
  default from: "noreply@notificatons.flailwhale.com"
  layout "mailer"
end
