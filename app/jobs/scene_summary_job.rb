# typed: true

class SceneSummaryJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(scene_id: Integer).void }
  def perform(scene_id)
    scene = Scene.find_by(id: scene_id)
    generate_and_deliver(scene) if scene
  rescue SceneSummaryService::ConfigurationError => error
    Rails.logger.error("SceneSummaryJob: #{error.message}")
  end

  private

  # Produce the summary, persist it, then push it to the waiting viewers.
  sig { params(scene: Scene).void }
  def generate_and_deliver(scene)
    upsert_summary(scene, SceneSummaryService.new(scene).call)
    broadcast(scene)
  end

  # Push the finished summary to every viewer waiting on the scene page, scoped
  # to the visibility classes that may see it (SceneSummaryBroadcast). Reloaded
  # from the row the upsert just wrote — upsert bypasses the in-memory object.
  sig { params(scene: Scene).void }
  def broadcast(scene)
    summary = SceneSummary.find_by(scene_id: scene.id)
    SceneSummaryBroadcast.new(summary).call if summary
  end

  UPDATE_ONLY_COLUMNS = T.let(
    %i[body model_used generated_at input_tokens output_tokens generated_by_id cost
       edited_at edited_by_id updated_at].freeze,
    T::Array[Symbol]
  )

  sig { params(scene: Scene, result: SceneSummaryService::Result).void }
  def upsert_summary(scene, result)
    SceneSummary.upsert(upsert_attributes(scene, result), unique_by: :scene_id, update_only: UPDATE_ONLY_COLUMNS)
  end

  sig { params(scene: Scene, result: SceneSummaryService::Result).returns(T::Hash[Symbol, T.untyped]) }
  def upsert_attributes(scene, result)
    now = Time.current

    result.to_summary_attributes.merge(
      scene_id: scene.id,
      generated_at: now,
      generated_by_id: generating_user(scene)&.id,
      edited_at: nil,
      edited_by_id: nil,
      created_at: now,
      updated_at: now
    )
  end

  # The user who triggered this generation: the game's GM, same acting
  # identity SceneSummaryService resolves a BYOK key for (see its #api_key).
  # Nil only if the game has no GM assigned — the same edge case the service
  # already treats as unfundable and rescues via ConfigurationError before
  # this job ever gets a result to upsert.
  sig { params(scene: Scene).returns(T.nilable(User)) }
  def generating_user(scene)
    scene.game&.game_master
  end
end
