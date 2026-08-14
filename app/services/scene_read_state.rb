# typed: strict
# frozen_string_literal: true

# Which of a scene's posts the viewer has already read.
#
# Only posts newer than the eligibility window are tracked: older ones are
# never shown as unread, so there is no reason to query them. A resolved scene
# tracks nothing at all — its posts are history, and the unread affordance is
# meaningless once the scene is closed.
#
# Extracted from ScenesController#show so the window boundary and the query's
# scoping are assertable directly, rather than only through a rendered page
# where a wrong-but-equivalent query produces identical HTML.
class SceneReadState
  extend T::Sig

  # Posts older than this are never marked unread.
  WINDOW = T.let(72.hours, ActiveSupport::Duration)

  sig do
    params(scene: Scene, posts: T::Enumerable[Post], user: User)
      .returns(T::Set[Integer])
  end
  def self.for(scene:, posts:, user:)
    return Set.new if scene.resolved?

    PostRead.where(user: user, post_id: eligible_ids(posts)).pluck(:post_id).to_set
  end

  # Ids of the posts recent enough to be worth a read-state lookup.
  sig { params(posts: T::Enumerable[Post]).returns(T::Array[Integer]) }
  def self.eligible_ids(posts)
    cutoff = WINDOW.ago
    posts.select { |post| post.created_at > cutoff }.map(&:id)
  end
end
