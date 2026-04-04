# typed: true

class NotificationPreference < ApplicationRecord
  extend T::Sig

  belongs_to :scene
  belongs_to :user

  # Opt-out model: no record means notifications ON
  sig { params(scene: Scene, user: User).returns(T::Boolean) }
  def self.muted?(scene, user)
    exists?(scene: scene, user: user, muted: true)
  end

  sig { params(scene: Scene, user: User).returns(NotificationPreference) }
  def self.toggle!(scene, user)
    pref = find_or_initialize_by(scene: scene, user: user)
    pref.muted = !pref.muted
    pref.save!
    pref
  end
end
