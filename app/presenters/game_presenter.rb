# typed: strict

# View model for a game and its viewer. Replaces the derived @is_gm boolean the
# controllers used to thread into views: the GM check is a method here, backed by
# the policy so a GM-only affordance can never diverge from what the controller
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
end
