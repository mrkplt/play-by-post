# typed: strict

class Shared::SceneSummaryEntryComponent < ApplicationComponent
  extend T::Sig

  sig { params(summary: SceneSummaryPresenter).void }
  def initialize(summary:)
    @summary = summary
  end

  sig { returns(String) }
  def scene_title
    @summary.scene_title
  end

  sig { returns(T.nilable(String)) }
  def formatted_resolved_at
    @summary.formatted_scene_resolved_at
  end

  sig { returns(String) }
  def scene_path
    @summary.scene_path
  end
end
