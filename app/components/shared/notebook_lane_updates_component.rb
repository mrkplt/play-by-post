# typed: strict

# The Turbo Stream payload for a notebook lane move: the lanes whose contents
# changed, each replaced whole.
#
# Rows are shared list markup carrying no per-entry id, so a move cannot remove
# one row and append another — it re-renders the lanes it emptied and filled.
# Replacing whole lanes also keeps their dividers and empty-state placeholders
# correct, which a targeted append never did.
#
# Which lanes those are comes from the entry's own dirty state after the save,
# so the move action needs no extra state to hand over.
class Shared::NotebookLaneUpdatesComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, notebook_entry: NotebookEntry).void }
  def initialize(game:, notebook_entry:)
    @game = game
    @notebook_entry = notebook_entry
  end

  # The destination lane, plus the source lane when the move actually changed
  # one. Re-submitting the current lane touches a single lane.
  sig { returns(T::Array[String]) }
  def affected_statuses
    [ @notebook_entry.status_previously_was, @notebook_entry.status ].compact.uniq
  end

  sig { returns(T::Array[Shared::NotebookLaneComponent]) }
  def lanes
    affected_statuses.map do |status|
      Shared::NotebookLaneComponent.new(game: @game, status: status, entries: entries_in(status))
    end
  end

  sig { params(status: String).returns(T::Array[NotebookEntry]) }
  def entries_in(status)
    @game.notebook_entries.where(status: status).order(:created_at).to_a
  end
end
