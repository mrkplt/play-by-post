# typed: strict

class Shared::SceneSummaryFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, scene: Scene, summary: SceneSummary).void }
  def initialize(game:, scene:, summary:)
    @game = T.let(game, Game)
    @scene = T.let(scene, Scene)
    @summary = T.let(summary, SceneSummary)
  end

  sig { returns(T::Boolean) }
  def editing?
    @summary.persisted?
  end

  sig { returns(String) }
  def heading
    editing? ? "Edit Scene Summary" : "Write Scene Summary"
  end

  sig { returns(String) }
  def submit_label
    editing? ? "Update Summary" : "Save Summary"
  end

  sig { returns(T::Boolean) }
  def show_ai_notice?
    editing? && SceneSummaryPresenter.new(@summary).ai_generated?
  end

  sig { returns(T::Boolean) }
  def has_errors?
    @summary.errors.any?
  end

  sig { returns(Integer) }
  def error_count
    @summary.errors.count
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @summary.errors.full_messages
  end
end
