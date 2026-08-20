# typed: strict
# frozen_string_literal: true

# Resolves a scene: stamps the resolution, notifies everyone still subscribed,
# and queues the AI summary when both AI Control Plane consent gates are open.
# Returns false when the scene was already resolved, so the caller can say so
# rather than resolving twice.
class SceneResolution
  extend T::Sig

  sig { params(scene: Scene, resolving_user: User).void }
  def initialize(scene, resolving_user:)
    @scene = scene
    @resolving_user = resolving_user
  end

  sig { params(resolution: T.untyped).returns(T::Boolean) }
  def call(resolution)
    return false if @scene.resolved?

    @scene.update!(resolved_at: Time.current, resolution: resolution)
    SceneNotifier.new(@scene).resolved
    SceneSummaryJob.perform_later(@scene.id) if ai_summary_consented?
    true
  end

  private

  # Two independent consent gates, both required: the game's own AI-summaries
  # toggle (a GM decision for the whole game) AND the resolving user's personal
  # AI consent (a user decision for themselves). The resolving user is who
  # SceneResolution is gated on, not the game's game_master record, because
  # only the GM can ever reach this call (ScenePolicy#resolve? is GM-only) —
  # the caller already knows who that is without a second lookup.
  sig { returns(T::Boolean) }
  def ai_summary_consented?
    T.must(@scene.game).ai_summaries_enabled? && user_ai_consented?
  end

  sig { returns(T::Boolean) }
  def user_ai_consented?
    @resolving_user.user_profile&.ai_summaries_consent? || false
  end
end
