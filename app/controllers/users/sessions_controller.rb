# typed: true

class Users::SessionsController < Devise::Passwordless::SessionsController
  extend T::Sig
  include TurnstileVerification

  before_action :verify_turnstile!, only: :create

  sig { void }
  def create
    email = (params.dig(:user, :email) || params[:email]).to_s.strip.downcase

    if email.blank?
      flash.now[:alert] = "Please enter an email address."
      self.resource = User.new
      return render :new, status: :unprocessable_content
    end

    self.resource = User.find_or_create_by!(email: email)
    self.resource.create_user_profile!(display_name: email.split("@").first) unless self.resource.user_profile
    # remember_me: true so the magic link issues a 30-day remember cookie
    # (config.remember_for) — the login persists across browser restarts and deploys.
    resource.send_magic_link(remember_me: true)
    @email_sent = true
    render :new
  end

  private

  # Re-render the sign-in form (same view as the blank-email failure) when the
  # bot check fails, instead of the module's default bare 403.
  sig { void }
  def turnstile_verification_failed
    flash.now[:alert] = "Please complete the verification challenge and try again."
    self.resource = User.new
    render :new, status: :unprocessable_content
  end
end
