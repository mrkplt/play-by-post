# typed: true

class PostDigestJob < ApplicationJob
  extend T::Sig

  queue_as :default

  WINDOW = T.let(24.hours, ActiveSupport::Duration)

  sig { void }
  def perform
    active_scenes.each { |scene| digest_scene(scene) }
  end

  sig { params(scene: Scene).void }
  def digest_scene(scene)
    participants_for(scene).each { |participant| digest_participant(scene, participant) }
  end

  sig { params(scene: Scene, participant: SceneParticipant).void }
  def digest_participant(scene, participant)
    user = participant.user
    return unless user && notify?(scene, user, participant)

    posts = posts_since_visit(scene, user, participant.last_visited_at)
    return if posts.empty?

    NotificationMailer.post_digest(scene, user, posts).deliver_later
  end

  # Whether this participant is owed a digest: not muted, and away for at least
  # the window. Pure decision — no query — so every branch is directly testable.
  sig { params(scene: Scene, user: User, participant: SceneParticipant).returns(T::Boolean) }
  def notify?(scene, user, participant)
    return false if NotificationPreference.muted?(scene, user)

    last_visit = participant.last_visited_at
    return false if last_visit && last_visit >= WINDOW.ago

    true
  end

  # --- Reads ---

  sig { returns(ActiveRecord::Relation) }
  def active_scenes
    Scene.active.joins(:posts).where(posts: { created_at: WINDOW.ago.. }).distinct
  end

  sig { params(scene: Scene).returns(T.untyped) }
  def participants_for(scene)
    scene.scene_participants.includes(:user)
  end

  sig { params(scene: Scene, user: User, last_visit: T.untyped).returns(T::Array[Post]) }
  def posts_since_visit(scene, user, last_visit)
    scene.posts
      .where("created_at > ?", cutoff(last_visit))
      .where.not(user: user)
      .order(:created_at)
      .to_a
  end

  # A participant who has never visited is treated as away for exactly the
  # window, same as one whose last visit falls outside it. `.presence` (rather
  # than `||`) reads as "fill in a default," not a branch on the parameter.
  sig { params(last_visit: T.untyped).returns(T.untyped) }
  def cutoff(last_visit)
    last_visit.presence || WINDOW.ago
  end
end
