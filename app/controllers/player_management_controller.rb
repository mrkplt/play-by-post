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
    @roster = T.let(roster, T.nilable(T::Array[GameMemberPresenter])) if game_policy.manage?
  end

  private

  # The Members list: each active player membership paired with that user's
  # first active character name, for the list's subtitle.
  sig { returns(T::Array[GameMemberPresenter]) }
  def roster
    characters_by_user = Character.first_active_name_by_user(game.characters.active)
    members = game.game_members.where.not(status: "banned").where(role: "player").includes(:user)
    members.map { |member| GameMemberPresenter.new(member, character_name: characters_by_user[member.user_id]) }
  end

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
