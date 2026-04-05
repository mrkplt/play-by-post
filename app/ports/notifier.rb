# typed: strict

module Ports
  module Notifier
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(scene: Scene, recipient: User).void }
    def notify_new_scene(scene:, recipient:); end

    sig { abstract.params(scene: Scene, recipient: User).void }
    def notify_scene_resolved(scene:, recipient:); end

    sig { abstract.params(scene: Scene, user: User, posts: T::Array[Post]).void }
    def notify_post_digest(scene:, user:, posts:); end
  end
end
