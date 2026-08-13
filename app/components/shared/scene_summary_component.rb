# typed: strict

class Shared::SceneSummaryComponent < ApplicationComponent
  extend T::Sig

  sig { params(summary: SceneSummaryPresenter, game: Game, scene: Scene, can_manage: T::Boolean).void }
  def initialize(summary:, game:, scene:, can_manage:)
    @summary = summary
    @game = game
    @scene = scene
    @can_manage = can_manage
  end

  sig { returns(String) }
  def status_badge_variant
    case @summary.status_label
    when "AI-generated" then "blue"
    when "Edited" then "yellow"
    else "gray"
    end
  end

  sig { returns(T::Boolean) }
  def can_manage?
    @can_manage
  end
end
