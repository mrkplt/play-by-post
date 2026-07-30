# typed: true

class User < ApplicationRecord
  extend T::Sig

  devise :magic_link_authenticatable, :rememberable

  has_one :user_profile, dependent: :destroy
  has_many :game_members, dependent: :destroy
  has_many :games, through: :game_members
  has_many :scene_participants, dependent: :destroy
  has_many :scenes, through: :scene_participants
  has_many :posts, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_one :rss_token, dependent: :destroy

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
end
