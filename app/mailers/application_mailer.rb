# typed: true

class ApplicationMailer < ActionMailer::Base
  default from: "noreply@flailwhale.com"
  layout "mailer"
end
