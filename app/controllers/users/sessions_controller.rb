# typed: true

class Users::SessionsController < Devise::Passwordless::SessionsController
  extend T::Sig

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
    send_magic_link(resource)
    @email_sent = true
    render :new
  end
end
