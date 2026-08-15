# typed: strict

class GameMembersController < ApplicationController
  extend T::Sig

  after_action :verify_authorized

  sig { void }
  def update
    member = game.game_members.find(params[:id])
    authorize member, :manage?
    return if require_manageable_member!(member)

    apply_status_change(member)
  end

  private

  # Looked up on demand rather than cached in a before_action ivar: this
  # controller renders no templates, so nothing needs it to persist as
  # request state.
  sig { returns(Game) }
  def game
    Game.find(params[:game_id])
  end

  # The GM's own membership is not modifiable — the rule lives in
  # GameMemberPolicy#update?; this surfaces its specific message. Only reached
  # once the caller already holds the :manage? capability (authorized above),
  # so this never fires for a user who isn't authorized at all. Returns
  # whether it redirected, so the caller knows to stop.
  sig { params(member: GameMember).returns(T::Boolean) }
  def require_manageable_member!(member)
    return false if policy(member).update?

    redirect_to_player_management(alert: "Cannot change GM status.")
    true
  end

  sig { params(member: GameMember).void }
  def apply_status_change(member)
    new_status = params.dig(:game_member, :status) || params[:status]
    return redirect_to_player_management(alert: "Invalid status.") unless GameMember::STATUSES.include?(new_status)

    member.update!(status: new_status)
    redirect_to_player_management(notice: "Player status updated.")
  end

  sig { params(notice: T.nilable(String), alert: T.nilable(String)).void }
  def redirect_to_player_management(notice: nil, alert: nil)
    redirect_to game_player_management_path(game), notice: notice, alert: alert
  end
end
