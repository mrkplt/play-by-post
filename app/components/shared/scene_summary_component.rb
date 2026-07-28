# typed: strict

class Shared::SceneSummaryComponent < ApplicationComponent
  extend T::Sig

  sig { params(summary: SceneSummaryPresenter, game: Game, scene: Scene, is_gm: T::Boolean).void }
  def initialize(summary:, game:, scene:, is_gm:)
    @summary = summary
    @game = game
    @scene = scene
    @is_gm = is_gm
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
  def is_gm?
    @is_gm
  end
end
