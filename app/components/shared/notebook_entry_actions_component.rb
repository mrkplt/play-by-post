# typed: strict

# The GM's actions on a notebook entry's edit screen: move it between lanes,
# promote it into a full Page, and delete it.
#
# The board carries only the lane picker, so this is where every other action
# on an entry lives. Once an entry has been promoted the Promote action is
# replaced by a link to the page it became, so a page is never created twice
# from the same entry.
class Shared::NotebookEntryActionsComponent < ApplicationComponent
  extend T::Sig

  CONFIRM = T.let("Delete this entry? This cannot be undone.", String)

  sig { params(game: Game, notebook_entry: NotebookEntry).void }
  def initialize(game:, notebook_entry:)
    @game = game
    @notebook_entry = notebook_entry
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(NotebookEntry) }
  attr_reader :notebook_entry

  sig { returns(String) }
  def confirm
    CONFIRM
  end

  sig { returns(T::Boolean) }
  def promoted?
    notebook_entry.promoted?
  end

  sig { returns(Page) }
  def promoted_page
    T.must(notebook_entry.promoted_page)
  end

  sig { returns(String) }
  def promoted_label
    "Promoted to: #{promoted_page.title}"
  end

  # No lanes on this screen to swap, so the move submits normally and the
  # controller redirects back with a confirmation.
  sig { returns(Shared::NotebookLaneSelectComponent) }
  def lane_select
    Shared::NotebookLaneSelectComponent.new(game: game, notebook_entry: notebook_entry, mode: :standalone)
  end
end
