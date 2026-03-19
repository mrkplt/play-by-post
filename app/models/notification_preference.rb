class NotificationPreference < ApplicationRecord
  belongs_to :scene
  belongs_to :user

  # Opt-out model: no record means notifications ON
  def self.muted?(scene, user)
    exists?(scene: scene, user: user, muted: true)
  end

  def self.toggle!(scene, user)
    pref = find_or_initialize_by(scene: scene, user: user)
    pref.muted = !pref.muted
    pref.save!
    pref
  end
end
