# typed: strict

# The Notebook tab panel on the Game View: a 4-column kanban of the game's
# notebook entries. New / Expand / Done are always visible; Discard is hidden
# by default behind a native <details> disclosure so it never intrudes when
# empty. Each column carries a stable id (notebook_column_<status>) so the
# move action's Turbo Stream response can target it directly.
class Shared::NotebookBoardComponent < ApplicationComponent
  extend T::Sig

  VISIBLE_STATUSES = T.let(%w[new expand done].freeze, T::Array[String])

  COLUMN_LABELS = T.let({
    "new" => "New",
    "expand" => "Expand",
    "done" => "Done",
    "discard" => "Discard"
  }.freeze, T::Hash[String, String])

  sig { params(game: Game, entries_by_status: T::Hash[String, T::Array[NotebookEntry]]).void }
  def initialize(game:, entries_by_status:)
    @game = T.let(game, Game)
    @entries_by_status = T.let(entries_by_status, T::Hash[String, T::Array[NotebookEntry]])
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(T::Array[String]) }
  def visible_statuses
    VISIBLE_STATUSES
  end

  sig { params(status: String).returns(String) }
  def column_label(status)
    T.must(COLUMN_LABELS[status])
  end

  sig { params(status: String).returns(T::Array[NotebookEntry]) }
  def entries_for(status)
    @entries_by_status.fetch(status, [])
  end

  sig { params(status: String).returns(String) }
  def column_id(status)
    "notebook_column_#{status}"
  end

  sig { returns(T::Array[NotebookEntry]) }
  def discarded_entries
    entries_for("discard")
  end

  sig { returns(T::Boolean) }
  def any_discarded?
    discarded_entries.any?
  end
end
