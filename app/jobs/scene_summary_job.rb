# typed: true

class SceneSummaryJob < ApplicationJob
  extend T::Sig

  queue_as :default

  FEATURE = "scene_summary"

  sig { params(scene_id: Integer, requested_by_id: Integer).void }
  def perform(scene_id, requested_by_id)
    scene = Scene.find_by(id: scene_id)
    generate_and_deliver(scene, requested_by_id) if scene
  rescue Ai::Funding::Exhausted => error
    Rails.logger.error("SceneSummaryJob: #{error.message}")
  end

  private

  # Produce the summary, persist it and its audit row atomically, then push
  # the summary to the waiting viewers.
  sig { params(scene: Scene, requested_by_id: Integer).void }
  def generate_and_deliver(scene, requested_by_id)
    prompt = SceneSummaryPrompt.new(scene).to_s
    result = Ai::UserGeneration.new(feature: FEATURE, game: T.must(scene.game)).call(prompt: prompt)

    ActiveRecord::Base.transaction do
      upsert_summary(scene, result)
      record_generation(scene, result, requested_by_id)
    end

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
    %i[body generated_at edited_at edited_by_id updated_at].freeze,
    T::Array[Symbol]
  )

  sig { params(scene: Scene, result: Ai::UserGeneration::Result).void }
  def upsert_summary(scene, result)
    SceneSummary.upsert(upsert_attributes(scene, result), unique_by: :scene_id, update_only: UPDATE_ONLY_COLUMNS)
  end

  sig { params(scene: Scene, result: Ai::UserGeneration::Result).returns(T::Hash[Symbol, T.untyped]) }
  def upsert_attributes(scene, result)
    now = Time.current

    {
      scene_id: scene.id,
      body: result.body,
      generated_at: now,
      edited_at: nil,
      edited_by_id: nil,
      created_at: now,
      updated_at: now
    }
  end

  # The permanent audit row for this generation: who requested it, whose key
  # paid, cost, model, and token counts. Written in the same transaction as
  # the summary upsert so the two can never diverge.
  sig { params(scene: Scene, result: Ai::UserGeneration::Result, requested_by_id: Integer).void }
  def record_generation(scene, result, requested_by_id)
    summary = T.must(SceneSummary.find_by(scene_id: scene.id))

    AiGeneration.create!(
      feature: FEATURE,
      model_used: result.model_used,
      input_tokens: result.input_tokens,
      output_tokens: result.output_tokens,
      cost: result.cost,
      requested_by_id: requested_by_id,
      funded_by_id: result.funded_by.id,
      asset_type: "SceneSummary",
      asset_id: summary.id
    )
  end
end
