# typed: strict

# The read view of a single Campaign Notebook entry: the markdown body
# rendered into a card, with GM-only Edit/Delete/Promote actions — mirrors
# Shared::PageDetailComponent. Once promoted, a "Promoted to:" link replaces
# the Promote action so a page is never created twice from this screen.
class Shared::NotebookDetailComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, notebook_entry: NotebookEntry).void }
  def initialize(game:, notebook_entry:)
    @game = T.let(game, Game)
    @notebook_entry = T.let(notebook_entry, NotebookEntry)
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(NotebookEntry) }
  attr_reader :notebook_entry

  sig { returns(T::Boolean) }
  def body?
    @notebook_entry.body.present?
  end

  sig { returns(T::Boolean) }
  def promoted?
    @notebook_entry.promoted?
  end

  sig { returns(T.nilable(Page)) }
  def promoted_page
    @notebook_entry.promoted_page
  end
end
