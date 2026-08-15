# typed: true

class PostDigestJob < ApplicationJob
  extend T::Sig

  queue_as :default

  WINDOW = T.let(24.hours, ActiveSupport::Duration)

  sig { void }
  def perform
    active_scenes.each do |scene|
      participants_for(scene).each do |participant|
        user = participant.user
        next unless user
        next unless notify?(scene, user, participant)

        posts = posts_since_visit(scene, user, participant.last_visited_at)
        next if posts.empty?

        delivery = NotificationMailer::Delivery.new(scene: scene, recipient: user)
        NotificationMailer.post_digest(delivery, posts).deliver_later
      end
    end
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
      .where("created_at > ?", last_visit || WINDOW.ago)
      .where.not(user: user)
      .order(:created_at)
      .to_a
  end
end
