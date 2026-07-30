require "rails_helper"

RSpec.describe "Sign in", type: :feature do
  it "shows confirmation after submitting email" do
    visit new_user_session_path

    fill_in "Email address", with: "newplayer@example.com"
    click_on "Send sign-in link"

    expect(page).to have_text("Check your email")
    expect(page).to have_text("We sent a sign-in link to your inbox")
  end

  it "creates the user if they don't exist" do
    visit new_user_session_path

    fill_in "Email address", with: "brand-new@example.com"
    click_on "Send sign-in link"

    expect(User.find_by(email: "brand-new@example.com")).to be_present
  end

  it "signs in via magic link and lands on dashboard" do
    user = FactoryBot.create(:user, :with_profile)

    sign_in_as(user)

    expect(page).to have_current_path(root_path)
    expect(page).to have_text(user.display_name)
  end

  it "sends a magic link email to the submitted address containing a sign-in URL" do
    user = FactoryBot.create(:user, :with_profile)

    visit new_user_session_path
    fill_in "Email address", with: user.email
    click_on "Send sign-in link"

    # The magic link is delivered via deliver_later; in a feature spec the job
    # runs in the Puma server thread, so the delivery can land just after the
    # click returns. Wait for it rather than reading deliveries once.
    mail = nil
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        mail = ActionMailer::Base.deliveries.find { |m| m.to.include?(user.email) }
        break if mail
        sleep 0.05
      end
    end

    expect(mail.to).to include(user.email)
    expect(mail.body.encoded).to match(/magic_link/)
  end
end
