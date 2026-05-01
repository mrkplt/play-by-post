# typed: strict

class Shared::SceneSummaryEntryComponent < ApplicationComponent
  extend T::Sig

  sig { params(summary: SceneSummaryPresenter, game: Game).void }
  def initialize(summary:, game:)
    @summary = summary
    @game = game
  end

  sig { returns(String) }
  def scene_title
    @summary.scene.title
  end

  sig { returns(T.nilable(String)) }
  def formatted_resolved_at
    resolved = @summary.scene.resolved_at
    return nil unless resolved

    resolved.strftime("%b %-d, %Y")
  end
end
