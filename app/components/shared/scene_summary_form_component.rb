# typed: strict

class Shared::SceneSummaryFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(summary: SceneSummaryPresenter).void }
  # mutant:disable
  def initialize(summary:)
    @summary = T.let(summary, SceneSummaryPresenter)
  end

  sig { returns(SceneSummaryPresenter) }
  attr_reader :summary

  sig { returns(T::Boolean) }
  def editing?
    summary.persisted?
  end

  sig { returns(String) }
  def heading
    mode_value(editing: "Edit Scene Summary", new: "Write Scene Summary")
  end

  sig { returns(String) }
  def submit_label
    mode_value(editing: "Update Summary", new: "Save Summary")
  end

  sig { returns(String) }
  def form_id
    mode_value(editing: "scene_summary_edit_form", new: "scene_summary_new_form")
  end

  sig { returns(T::Boolean) }
  def show_ai_notice?
    editing? && summary.ai_generated?
  end

  # Live draft autosave applies only to a persisted summary — a new summary has
  # no row to autosave onto, so its draft state is chosen at create.
  sig { returns(T::Boolean) }
  def autosave?
    editing?
  end

  # Where the editor autosaves this summary's draft (edit only).
  sig { returns(String) }
  def save_draft_path
    summary.routes.save_draft_path
  end

  # Whether this summary is currently an unpublished draft — sets the toggle's
  # initial state on edit.
  sig { returns(T::Boolean) }
  def draft?
    summary.draft?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    summary.errors.full_messages
  end

  private

  # The single editing?-keyed branch heading/submit_label/form_id go
  # through, so the new/edit distinction is tested once per call rather
  # than repeating the ternary in each label method.
  sig { type_parameters(:T).params(editing: T.type_parameter(:T), new: T.type_parameter(:T)).returns(T.type_parameter(:T)) }
  def mode_value(editing:, new:)
    editing? ? editing : new
  end
end
