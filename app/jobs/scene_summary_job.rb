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
    result = generate(scene)
    persist(scene, result, requested_by_id)
    broadcast(scene)
  end

  sig { params(scene: Scene).returns(Ai::UserGeneration::Result) }
  def generate(scene)
    Ai::UserGeneration
      .new(feature: FEATURE, game: T.must(scene.game))
      .call(prompt: SceneSummaryPrompt.new(scene).to_s)
  end

  # One transaction for the summary upsert, its version snapshot, and its audit
  # row, so the three can never diverge. Reloaded from the row the upsert just
  # wrote — upsert bypasses the in-memory object, so it also bypasses
  # Versionable::Model's save-time snapshot; the version is written explicitly
  # here instead, recording that this revision was AI-authored (generated_at set)
  # and attributing it to the requester.
  sig { params(scene: Scene, result: Ai::UserGeneration::Result, requested_by_id: Integer).void }
  def persist(scene, result, requested_by_id)
    scene_id = T.must(scene.id)

    ActiveRecord::Base.transaction do
      SceneSummary.upsert(upsert_attributes(scene_id, result.body), unique_by: :scene_id, update_only: UPDATE_ONLY_COLUMNS)
      summary = T.must(SceneSummary.find_by(scene_id: scene_id))
      snapshot_generation(summary, requested_by_id)
      record_generation(summary_id: summary.id, result: result, requested_by_id: requested_by_id)
    end
  end

  # The version row for an AI generation. The upsert path skips Versionable's
  # save override, so the snapshot is written here from the freshly-loaded
  # summary — carrying its generated_at (this revision was AI-authored) and
  # attributed to the requester, who has no Current.user in a job.
  sig { params(summary: SceneSummary, requested_by_id: Integer).void }
  def snapshot_generation(summary, requested_by_id)
    summary.scene_summary_versions.create!(
      body: summary.body,
      generated_at: summary.generated_at,
      edited_by_id: requested_by_id
    )
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

  sig { params(scene_id: Integer, body: String).returns(T::Hash[Symbol, T.untyped]) }
  def upsert_attributes(scene_id, body)
    now = Time.current

    {
      scene_id: scene_id,
      body: body,
      generated_at: now,
      edited_at: nil,
      edited_by_id: nil,
      created_at: now,
      updated_at: now
    }
  end

  # The permanent audit row for this generation: who requested it, whose key
  # paid, cost, model, and token counts.
  sig { params(summary_id: Integer, result: Ai::UserGeneration::Result, requested_by_id: Integer).void }
  def record_generation(summary_id:, result:, requested_by_id:)
    AiGeneration.create!(
      feature: FEATURE,
      model_used: result.model_used,
      input_tokens: result.input_tokens,
      output_tokens: result.output_tokens,
      cost: result.cost,
      requested_by_id: requested_by_id,
      funded_by_id: result.funded_by.id,
      asset_type: "SceneSummary",
      asset_id: summary_id
    )
  end
end
