# typed: strict

# A single Campaign Notebook kanban card. Renders in one of two modes so a
# Turbo Stream `replace` on `dom_id(notebook_entry)` can swap between them
# in place, with no page navigation:
#
# - :read — title, the markdown body clamped to a fixed card height in CSS, a
#   lane <select> that submits itself via
#   Turbo on change, and GM actions (Edit / Promote / Delete).
# - :edit — an inline form (title + markdown editor) posting to #update via
#   Turbo Stream, with Save/Cancel.
class Shared::NotebookCardComponent < ApplicationComponent
  extend T::Sig

  STATUS_LABELS = T.let({
    "new" => "New",
    "expand" => "Expand",
    "done" => "Done",
    "discard" => "Discard"
  }.freeze, T::Hash[String, String])

  sig { params(game: Game, notebook_entry: NotebookEntry, mode: Symbol).void }
  def initialize(game:, notebook_entry:, mode: :read)
    @game = T.let(game, Game)
    @notebook_entry = T.let(notebook_entry, NotebookEntry)
    @mode = T.let(mode, Symbol)
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(NotebookEntry) }
  attr_reader :notebook_entry

  sig { returns(T::Boolean) }
  def edit_mode?
    @mode == :edit
  end

  sig { returns(T::Boolean) }
  def body?
    @notebook_entry.body.present?
  end

  # Full markdown body. The kanban card clamps it to a fixed height in CSS
  # (max-h + overflow-hidden) rather than truncating the text, so cards stay a
  # uniform height without cutting the markdown mid-tag.
  sig { returns(T.nilable(String)) }
  def body
    @notebook_entry.body
  end

  sig { returns(T::Boolean) }
  def promoted?
    @notebook_entry.promoted?
  end

  sig { returns(T.nilable(Page)) }
  def promoted_page
    @notebook_entry.promoted_page
  end

  sig { returns(T::Array[[ String, String ]]) }
  def status_options
    NotebookEntry::STATUSES.map { |status| [ T.must(STATUS_LABELS[status]), status ] }
  end

  sig { returns(String) }
  def card_classes
    "bg-card border border-card-border rounded-card p-3 flex flex-col gap-2"
  end
end
