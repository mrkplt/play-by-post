# typed: strict

# The Notebook tab panel on the Game View: a 4-column kanban of the game's
# notebook entries. New / Expand / Done are always visible; Discard is hidden
# by default behind a native <details> disclosure so it never intrudes when
# empty. Each column carries a stable id (notebook_column_<status>) so the
# move action's Turbo Stream response can target it directly.
#
# A lane is a list of titles, not cards: entries are GM scratchpad, so the
# board shows what an entry is called and lets the GM move it between lanes.
# Every other action — edit, delete, promote — lives on the entry's own edit
# screen, which is where the title links.
class Shared::NotebookBoardComponent < ApplicationComponent
  extend T::Sig

  VISIBLE_STATUSES = T.let(%w[new expand done].freeze, T::Array[String])

  DISCARD_STATUS = T.let("discard", String)


  sig { params(game: Game, entries_by_status: T::Hash[String, T::Array[NotebookEntry]]).void }
  def initialize(game:, entries_by_status:)
    @game = game
    @entries_by_status = entries_by_status
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(T::Array[String]) }
  def visible_statuses
    VISIBLE_STATUSES
  end

  sig { params(status: String).returns(T::Array[NotebookEntry]) }
  def entries_for(status)
    @entries_by_status.fetch(status, [])
  end

  sig { params(status: String).returns(String) }
  def column_id(status)
    self.class.column_id(status)
  end

  # The move action's Turbo Stream response replaces whole lanes by this id,
  # so it needs to name them without building a board.
  sig { params(status: String).returns(String) }
  def self.column_id(status)
    "notebook_column_#{status}"
  end

  # A lane knows its own label and whether it hides behind a disclosure, so the
  # board only says which entries belong to it.
  sig { params(status: String).returns(Shared::NotebookLaneComponent) }
  def lane_for(status)
    Shared::NotebookLaneComponent.new(game: game, status: status, entries: entries_for(status))
  end

  sig { returns(T::Array[Shared::NotebookLaneComponent]) }
  def lanes
    (visible_statuses + [ DISCARD_STATUS ]).map { |status| lane_for(status) }
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
