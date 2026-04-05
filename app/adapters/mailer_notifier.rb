# typed: strict

class MailerNotifier
  extend T::Sig
  include Ports::Notifier

  sig { override.params(scene: Scene, recipient: User).void }
  def notify_new_scene(scene:, recipient:)
    NotificationMailer.new_scene(scene, recipient).deliver_later
  end

  sig { override.params(scene: Scene, recipient: User).void }
  def notify_scene_resolved(scene:, recipient:)
    NotificationMailer.scene_resolved(scene, recipient).deliver_later
  end

  sig { override.params(scene: Scene, user: User, posts: T::Array[Post]).void }
  def notify_post_digest(scene:, user:, posts:)
    NotificationMailer.post_digest(scene, user, posts).deliver_later
  end
end
