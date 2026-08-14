# typed: strict

class PlayerManagementController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_access!
  after_action :verify_authorized

  sig { void }
  def show
    authorize @game, :manage_players?
    @game_presenter = T.let(
      GamePresenter.new(T.must(@game), policy: policy(@game), current_user: current_user),
      T.nilable(GamePresenter)
    )

    if policy(@game).manage?
      characters_by_user = character_names_by_user
      members = T.must(@game).game_members.where.not(status: "banned").where(role: "player").includes(:user)
      @roster = T.let(
        members.map { |m| GameMemberPresenter.new(m, character_name: characters_by_user[m.user_id]) },
        T.nilable(T::Array[GameMemberPresenter])
      )
    end
  end

  private

  # First active character name per user, for the Members list subtitle.
  sig { returns(T::Hash[Integer, String]) }
  def character_names_by_user
    T.must(@game).characters.active.each_with_object({}) do |c, h|
      h[c.user_id] ||= c.name
    end
  end

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  # Not redundant with `authorize`: this gates before the action runs and gives
  # "cannot see this game at all" its own message, distinct from a denial of
  # the specific thing being attempted.
  sig { void }
  def require_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).manage_players?
  end
end
