# typed: strict

# One swimlane of the Campaign Notebook board: a labelled list of the entries
# in a single status.
#
# Every lane is the same thing. Whether it opens collapsed behind a disclosure
# is a property of the lane, not of the screen drawing it, so `collapsible:`
# and `default_collapsed:` are parameters rather than a container each caller
# hand-builds around the lane.
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

  # How a lane presents itself, keyed by status: its heading, and whether it
  # sits behind a disclosure. Disclosure is one property with three states, not
  # two independent flags — a lane is either always shown (:none), or behind a
  # disclosure that starts closed (:collapsed) or open (:expanded).
  #
  # Discard is the one lane behind a disclosure: it is a bin, not part of the
  # working board, so it should not intrude when a GM is not looking for it.
  # Its label doubles as the disclosure summary, so it reads as an action.
  PRESENTATION = T.let({
    "new" => { label: "New", disclosure: :none },
    "expand" => { label: "Expand", disclosure: :none },
    "done" => { label: "Done", disclosure: :none },
    "discard" => { label: "Show discarded", disclosure: :collapsed }
  }.freeze, T::Hash[String, T::Hash[Symbol, T.untyped]])

  DISCLOSURES = T.let(%i[none collapsed expanded].freeze, T::Array[Symbol])

  sig { params(status: String).returns(String) }
  def self.label_for(status)
    PRESENTATION.fetch(status).fetch(:label)
  end

  sig { params(status: String).returns(Symbol) }
  def self.disclosure_for(status)
    PRESENTATION.fetch(status).fetch(:disclosure)
  end

  sig do
    params(
      game: GamePresenter,
      status: String,
      entries: T::Array[NotebookEntryPresenter],
      disclosure: Symbol
    ).void
  end
  def initialize(game:, status:, entries:, disclosure: :default)
    @game = game
    @status = status
    @entries = entries
    @disclosure = disclosure
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(T::Array[NotebookEntryPresenter]) }
  attr_reader :entries

  sig { returns(String) }
  def label
    self.class.label_for(@status)
  end

  # `:default` means "however this status normally presents", resolved here so
  # the constructor stays a plain assignment.
  sig { returns(Symbol) }
  def disclosure
    return self.class.disclosure_for(@status) if @disclosure == :default

    @disclosure
  end

  sig { returns(T::Boolean) }
  def collapsible?
    disclosure != :none
  end

  # The <details> attributes, so the template states no conditionals.
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def disclosure_attributes
    { class: "mt-1", open: disclosure == :expanded }
  end

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
  sig { params(entry: NotebookEntryPresenter).returns(Shared::ListEntryComponent::Row) }
  def row_for(entry)
    {
      title: entry.title,
      href: helpers.edit_game_notebook_entry_path(game, entry),
      controls: Shared::NotebookLaneSelectComponent.new(game: game, notebook_entry: entry)
    }
  end
end
