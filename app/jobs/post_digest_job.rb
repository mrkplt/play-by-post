# typed: true

class PostDigestJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { void }
  def perform
    # Find all active scenes with posts in the last 24 hours
    active_scenes = Scene.active.joins(:posts).where(posts: { created_at: 24.hours.ago.. }).distinct

    active_scenes.each do |scene|
      scene.scene_participants.includes(:user).each do |participant|
        user = participant.user
        next unless user
        next if NotificationPreference.muted?(scene, user)

        lva = participant.last_visited_at
        next if lva && lva >= 24.hours.ago

        posts_since_visit = scene.posts
          .where("created_at > ?", lva || 24.hours.ago)
          .where.not(user: user)
          .order(:created_at)

        next if posts_since_visit.empty?

        NotificationMailer.post_digest(scene, user, posts_since_visit.to_a).deliver_later
      end
    end
  end
end
