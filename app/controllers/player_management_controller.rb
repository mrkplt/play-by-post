# typed: strict

class PlayerManagementController < ApplicationController
  extend T::Sig

  before_action :require_access!
  after_action :verify_authorized

  sig { void }
  def show
    game_policy = policy(game)
    authorize game, :manage_players?
    @game_presenter = T.let(
      GamePresenter.new(game, policy: game_policy, current_user: current_user),
      T.nilable(GamePresenter)
    )
    @roster = T.let(GameMemberRoster.new(game).rows, T.nilable(T::Array[GameMemberPresenter])) if game_policy.manage?
  end

  private

  # Used only internally (authorize, presenter construction, associations) —
  # never read by a template, so it is not an ivar. `params[:game_id]` is a
  # primary-key lookup, cheap enough to repeat across the handful of calls in
  # a single request rather than reach for ivar memoization.
  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  # Not redundant with `authorize`: this gates before the action runs and gives
  # "cannot see this game at all" its own message, distinct from a denial of
  # the specific thing being attempted.
  sig { void }
  def require_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).manage_players?
  end
end
