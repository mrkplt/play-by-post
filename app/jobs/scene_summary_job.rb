# typed: true

class SceneSummaryJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(scene_id: Integer).void }
  def perform(scene_id)
    scene = Scene.find_by(id: scene_id)
    return unless scene

    upsert_summary(scene, SceneSummaryService.new(scene).call)
  rescue SceneSummaryService::ConfigurationError => error
    Rails.logger.error("SceneSummaryJob: #{error.message}")
  end

  private

  UPDATE_ONLY_COLUMNS = T.let(
    %i[body model_used generated_at input_tokens output_tokens edited_at edited_by_id updated_at].freeze,
    T::Array[Symbol]
  )

  sig { params(scene: Scene, result: SceneSummaryService::Result).void }
  def upsert_summary(scene, result)
    SceneSummary.upsert(upsert_attributes(scene, result), unique_by: :scene_id, update_only: UPDATE_ONLY_COLUMNS)
  end

  sig { params(scene: Scene, result: SceneSummaryService::Result).returns(T::Hash[Symbol, T.untyped]) }
  def upsert_attributes(scene, result)
    now = Time.current

    {
      scene_id: scene.id,
      body: result.body,
      model_used: result.model_used,
      generated_at: now,
      input_tokens: result.input_tokens,
      output_tokens: result.output_tokens,
      edited_at: nil,
      edited_by_id: nil,
      created_at: now,
      updated_at: now
    }
  end
end
