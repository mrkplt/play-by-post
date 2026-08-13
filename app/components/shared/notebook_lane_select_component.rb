# typed: strict

# The lane picker for a Campaign Notebook entry: a <select> of the kanban
# statuses that submits itself on change, moving the entry between swimlanes
# without a page navigation.
#
# It is the only control on a notebook board row — every other action lives on
# the entry's edit screen — and it also appears on that edit screen, so a GM can
# move an entry without returning to the board.
class Shared::NotebookLaneSelectComponent < ApplicationComponent
  extend T::Sig

  STATUS_LABELS = T.let({
    "new" => "New",
    "expand" => "Expand",
    "done" => "Done",
    "discard" => "Discard"
  }.freeze, T::Hash[String, String])

  SELECT_CLASS = T.let(
    "border border-input-border rounded-control px-2 py-1.5 text-xs text-ink bg-card",
    String
  )

  sig { params(game: Game, notebook_entry: NotebookEntry).void }
  def initialize(game:, notebook_entry:)
    @game = game
    @notebook_entry = notebook_entry
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(NotebookEntry) }
  attr_reader :notebook_entry

  sig { returns(T.nilable(String)) }
  def selected_status
    notebook_entry.status
  end

  sig { returns(T::Array[[ String, String ]]) }
  def status_options
    NotebookEntry::STATUSES.map { |status| [ T.must(STATUS_LABELS[status]), status ] }
  end
end
