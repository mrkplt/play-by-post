# typed: true

class User < ApplicationRecord
  extend T::Sig

  devise :magic_link_authenticatable, :rememberable

  # Every user needs a stable secret so the passwordless model has a real
  # authenticatable_salt (see #authenticatable_salt). Generated on create and
  # regenerated after a sign-out cleared it (see #after_magic_link_authentication).
  before_create :ensure_remember_token

  has_one :user_profile, dependent: :destroy
  has_many :game_members, dependent: :destroy
  has_many :games, through: :game_members
  has_many :scene_participants, dependent: :destroy
  has_many :scenes, through: :scene_participants
  has_many :posts, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :feedback, dependent: :destroy
  has_many :rss_tokens, dependent: :destroy

  sig { returns(T.nilable(String)) }
  def display_name
    user_profile&.display_name
  end

  # Deliver Devise mail (the passwordless magic link) through Active Job /
  # Solid Queue so it is sent by the worker, matching every other mailer in the
  # app (NotificationMailer, ExportMailer, InvitationMailer all use
  # deliver_later). Devise's default sends the magic link with deliver_now,
  # inline in the web request — the only email that bypassed the worker.
  sig { params(notification: Symbol, args: T.untyped).void }
  def send_devise_notification(notification, *args)
    message = T.unsafe(self).devise_mailer.send(notification, self, *args)
    if message.respond_to?(:deliver_later)
      message.deliver_later
    else
      message.deliver_now
    end
  end

  # Passwordless users have no encrypted_password, so Devise's default
  # authenticatable_salt is nil — which makes session validation a permanent
  # no-op (`nil == nil`) and makes `:rememberable` raise. Anchoring the salt to
  # remember_token gives sessions a real, per-user secret: rotating the token
  # invalidates that user's sessions and remember-me cookie.
  sig { returns(T.nilable(String)) }
  def authenticatable_salt
    remember_token
  end

  # Runs during magic-link authentication, before the session is serialized. A
  # prior sign-out clears remember_token (expire_all_remember_me_on_sign_out), so
  # regenerate it here to guarantee the salt is present for the new session.
  sig { void }
  def after_magic_link_authentication
    update_column(:remember_token, Devise.friendly_token) if remember_token.blank?
  end

  private

  sig { void }
  def ensure_remember_token
    self.remember_token ||= Devise.friendly_token
  end
end
