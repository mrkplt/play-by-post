module SignInHelper
  # Signs a user in through the real magic-link confirmation route, but visits
  # the tokenized URL directly instead of scraping it out of a delivered email.
  #
  # The magic-link email is delivered via deliver_later (so it goes through the
  # worker in production). In feature specs the mailer job runs in the Puma
  # server thread and does not reliably land in ActionMailer::Base.deliveries
  # for the test thread to read, so driving sign-in off the delivered email is
  # flaky. Generating the same token the mailer would embed and visiting
  # user_magic_link_path is delivery-independent and still exercises the token
  # confirmation path.
  def sign_in_as(user)
    visit destroy_user_session_path

    token = Devise::Passwordless::SignedGlobalIDTokenizer.encode(user)
    visit user_magic_link_path(user: { email: user.email, token: token })
  end
end

RSpec.configure do |config|
  config.include SignInHelper, type: :feature
end
