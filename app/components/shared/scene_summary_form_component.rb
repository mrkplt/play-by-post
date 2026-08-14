# typed: strict

class Shared::SceneSummaryFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, scene: Scene, summary: SceneSummaryPresenter).void }
  # mutant:disable
  def initialize(game:, scene:, summary:)
    @game = T.let(game, Game)
    @scene = T.let(scene, Scene)
    @summary = T.let(summary, SceneSummaryPresenter)
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

  sig { returns(String) }
  def form_id
    editing? ? "scene_summary_edit_form" : "scene_summary_new_form"
  end

  sig { returns(T::Boolean) }
  def show_ai_notice?
    editing? && @summary.ai_generated?
  end

  sig { returns(T::Boolean) }
  def has_errors?
    @summary.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @summary.errors.full_messages
  end
end
