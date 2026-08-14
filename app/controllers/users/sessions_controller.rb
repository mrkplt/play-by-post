# typed: strict

class Users::SessionsController < Devise::Passwordless::SessionsController
  extend T::Sig
  include TurnstileVerification

  before_action :verify_turnstile!, only: :create

  # Overrides Devise::SessionsController#new (GET /users/sign_in) rather than
  # calling super: this is also the recall target Warden re-routes to when a
  # magic-link token fails authentication (expired, already used), so the
  # presenter must be built for it too, not only for the #create paths this
  # controller overrides below. The body mirrors Devise's own #new — build an
  # empty resource for the form — with the addition of the presenter.
  sig { void }
  def new
    assign_blank_sign_in_presenter
  end

  sig { void }
  def create
    email = (params.dig(:user, :email) || params[:email]).to_s.strip.downcase
    return reject_blank_email if email.blank?

    send_magic_link_to(email)
  end

  private

  # Re-render the sign-in form (same view as the blank-email failure) when the
  # bot check fails, instead of the module's default bare 403.
  sig { void }
  def turnstile_verification_failed
    flash.now[:alert] = "Please complete the verification challenge and try again."
    assign_blank_sign_in_presenter
    render :new, status: :unprocessable_content
  end

  sig { void }
  def reject_blank_email
    flash.now[:alert] = "Please enter an email address."
    assign_blank_sign_in_presenter
    render :new, status: :unprocessable_content
  end

  sig { params(email: String).void }
  def send_magic_link_to(email)
    self.resource = User.find_or_create_by!(email: email)
    resource.create_user_profile!(display_name: email.split("@").first) unless resource.user_profile
    # remember_me: true so the magic link issues a 30-day remember cookie
    # (config.remember_for) — the login persists across browser restarts and deploys.
    resource.send_magic_link(remember_me: true)
    @sign_in_presenter = T.let(SignInPresenter.new(resource, email_sent: true), T.nilable(SignInPresenter))
    render :new
  end

  sig { void }
  def assign_blank_sign_in_presenter
    self.resource = User.new
    @sign_in_presenter = T.let(SignInPresenter.new(resource), T.nilable(SignInPresenter))
  end
end
