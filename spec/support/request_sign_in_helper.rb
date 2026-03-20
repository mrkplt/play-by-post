module RequestSignInHelper
  include Warden::Test::Helpers

  def sign_in(user)
    login_as(user, scope: :user)
  end

  def sign_out
    logout(:user)
  end
end

RSpec.configure do |config|
  config.include RequestSignInHelper, type: :request
  config.after(:each, type: :request) { Warden.test_reset! }
end
