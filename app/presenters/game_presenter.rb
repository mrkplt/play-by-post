# typed: strict

# View model for a game and its viewer. Replaces the derived @can_manage boolean
# the controllers used to thread into views: the GM check is a method here, backed
# by the policy so a GM-only affordance can never diverge from what the controller
# authorizes.
class GamePresenter < BasePresenter
  extend T::Sig

  sig { params(model: Game, current_user: User).void }
  def initialize(model, current_user)
    super(model)
    @current_user = T.let(current_user, User)
  end

  # The viewer runs this game.
  sig { returns(T::Boolean) }
  def gm?
    GamePolicy.new(@current_user, @model).update?
  end

  # Outstanding (unaccepted) invitations for this game, newest first — the data
  # behind the GM-only invite panel on the Roster tab.
  sig { returns(T::Array[Invitation]) }
  def pending_invitations
    @model.invitations.pending.order(created_at: :desc).to_a
  end

  # The game's pages, alphabetised by title — the data behind the Pages tab.
  sig { returns(T::Array[Page]) }
  def pages
    @model.pages.order(:title).to_a
  end

  # The game's links, newest first — the data behind the Links tab.
  sig { returns(T::Array[GameLink]) }
  def links
    @model.game_links.order(created_at: :desc).to_a
  end

  # The game's notebook entries, grouped by kanban lane (oldest first within
  # each lane) — the data behind the GM-only Notebook tab's board.
  sig { returns(T::Hash[String, T::Array[NotebookEntry]]) }
  def notebook_entries
    @model.notebook_entries.order(:created_at).to_a.group_by(&:status)
  end
end
