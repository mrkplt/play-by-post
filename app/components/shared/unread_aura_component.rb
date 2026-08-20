# typed: strict

# The scene's posts list — the `#posts` container under `unread-aura` control.
# On connect the controller adds the glow aura to unread posts and, after a
# short dwell, POSTs each post's mark-read URL. `id="posts"` is the Turbo Stream
# append target for newly created posts (posts/create.turbo_stream.erb), so it
# is fixed, not a parameter.
#
# Owns the list: it renders one Shared::PostItemComponent per post, or the
# empty-state message when there are none. Takes presentation-ready data — the
# post presenters, the scene presenter, and the read-post id set — never raw
# models.
class Shared::UnreadAuraComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      post_presenters: T::Array[PostPresenter],
      scene: ScenePresenter,
      read_post_ids: T::Set[Integer]
    ).void
  end
  def initialize(post_presenters:, scene:, read_post_ids:)
    @post_presenters = post_presenters
    @scene = scene
    @read_post_ids = read_post_ids
  end

  sig { returns(T::Array[PostPresenter]) }
  attr_reader :post_presenters

  sig { returns(ScenePresenter) }
  attr_reader :scene

  sig { returns(T::Set[Integer]) }
  attr_reader :read_post_ids

  sig { returns(T::Boolean) }
  def posts_empty?
    post_presenters.empty?
  end
end
