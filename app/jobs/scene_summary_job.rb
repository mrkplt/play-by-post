# typed: true

class SceneSummaryJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(scene_id: Integer).void }
  def perform(scene_id)
    scene = Scene.find_by(id: scene_id)
    return unless scene

    result = SceneSummaryService.new(scene).call

    SceneSummary.upsert(
      {
        scene_id: scene.id,
        body: result.body,
        model_used: result.model_used,
        generated_at: Time.current,
        input_tokens: result.input_tokens,
        output_tokens: result.output_tokens,
        edited_at: nil,
        edited_by_id: nil,
        created_at: Time.current,
        updated_at: Time.current
      },
      unique_by: :scene_id,
      update_only: %i[body model_used generated_at input_tokens output_tokens edited_at edited_by_id updated_at]
    )
  rescue SceneSummaryService::ConfigurationError => e
    Rails.logger.error("SceneSummaryJob: #{e.message}")
  end
end
