# typed: strict

# One swimlane of the Campaign Notebook board: the entries in a single status,
# rendered as a list of titles.
#
# The lane owns the element the move action targets. A move changes which lane
# an entry belongs to, so its Turbo Stream response re-renders the source and
# destination lanes through this component — that keeps row dividers and the
# empty-state placeholder correct, which appending a single row could not.
class Shared::NotebookLaneComponent < ApplicationComponent
  extend T::Sig

  EMPTY_TEXT = T.let("Nothing here.", String)
  DISCARD_EMPTY_TEXT = T.let("Nothing discarded.", String)

  # Discard is the one lane a GM expects to be empty, so it says so in its own
  # words rather than reading as an oversight.
  EMPTY_TEXTS = T.let({ "discard" => DISCARD_EMPTY_TEXT }.freeze, T::Hash[String, String])

  sig { params(status: String).returns(String) }
  def self.empty_text_for(status)
    EMPTY_TEXTS.fetch(status, EMPTY_TEXT)
  end

  sig { params(game: Game, status: String, entries: T::Array[NotebookEntry]).void }
  def initialize(game:, status:, entries:)
    @game = game
    @status = status
    @entries = entries
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(T::Array[NotebookEntry]) }
  attr_reader :entries

  sig { returns(String) }
  def empty_text
    self.class.empty_text_for(@status)
  end

  sig { returns(String) }
  def dom_id
    Shared::NotebookBoardComponent.column_id(@status)
  end

  sig { returns(T::Array[Shared::ListEntryComponent::Row]) }
  def rows
    entries.map { |entry| row_for(entry) }
  end

  # A row is a title linking to the entry's edit screen, with the lane picker
  # as its only control — every other action lives on that edit screen.
  sig { params(entry: NotebookEntry).returns(Shared::ListEntryComponent::Row) }
  def row_for(entry)
    {
      title: entry.title.to_s,
      href: helpers.edit_game_notebook_entry_path(game, entry),
      controls: Shared::NotebookLaneSelectComponent.new(game: game, notebook_entry: entry)
    }
  end
end
