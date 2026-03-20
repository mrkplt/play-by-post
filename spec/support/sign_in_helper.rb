module SignInHelper
  def sign_in_as(user)
    visit destroy_user_session_path
    visit new_user_session_path
    fill_in "Email address", with: user.email
    click_on "Send sign-in link"

    mail = ActionMailer::Base.deliveries.last
    html_body = mail.html_part&.body&.decoded || mail.body.decoded
    token_url = html_body[/href="([^"]+magic_link[^"]+)"/, 1]&.gsub("&amp;", "&")
    local_url = token_url.sub(%r{https?://[^/]+}, "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}")

    visit local_url
  end
end

RSpec.configure do |config|
  config.include SignInHelper, type: :feature
end
