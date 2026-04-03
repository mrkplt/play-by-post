# typed: true

Warden::Manager.after_set_user except: :fetch do |user, _auth, _opts|
  next unless user.is_a?(User)

  profile = user.user_profile || user.build_user_profile
  profile.last_login_at = Time.current
  profile.save!
end
