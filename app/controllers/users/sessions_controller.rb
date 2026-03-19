class Users::SessionsController < Devise::Passwordless::SessionsController
  def create
    email = (params.dig(:user, :email) || params[:email]).to_s.strip.downcase
    self.resource = User.find_or_create_by!(email: email)
    self.resource.create_user_profile!(display_name: email.split("@").first) unless self.resource.user_profile
    send_magic_link(resource)
    @email_sent = true
    render :new
  end

  protected

  def after_sign_in_path_for(resource)
    upsert_user_profile(resource)
    root_path
  end

  private

  def upsert_user_profile(user)
    profile = user.user_profile || user.build_user_profile
    profile.last_login_at = Time.current
    profile.save!
  end
end
