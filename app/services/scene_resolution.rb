# typed: strict
# frozen_string_literal: true

# Resolves a scene: stamps the resolution, notifies everyone still subscribed,
# and queues the AI summary when the game has them switched on. Returns false
# when the scene was already resolved, so the caller can say so rather than
# resolving twice.
class SceneResolution
  extend T::Sig

  sig { params(scene: Scene).void }
  def initialize(scene)
    @scene = scene
  end

  sig { params(resolution: T.untyped).returns(T::Boolean) }
  def call(resolution)
    return false if @scene.resolved?

    @scene.update!(resolved_at: Time.current, resolution: resolution)
    SceneNotifier.new(@scene).resolved
    SceneSummaryJob.perform_later(@scene.id) if T.must(@scene.game).ai_summaries_enabled?
    true
  end
end
