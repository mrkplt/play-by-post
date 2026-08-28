# typed: strict

class GameMembersController < ApplicationController
  extend T::Sig
  include InPlaceRender

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
    Game.find_by!(slug: params[:game_id])
  end

  # The GM's own membership is not modifiable — the rule lives in
  # GameMemberPolicy#update?; this surfaces its specific message. Only reached
  # once the caller already holds the :manage? capability (authorized above),
  # so this never fires for a user who isn't authorized at all. Returns
  # whether it redirected, so the caller knows to stop.
  sig { params(member: GameMember).returns(T::Boolean) }
  def require_manageable_member!(member)
    return false if policy(member).update?

    render_roster(alert: "Cannot change GM status.")
    true
  end

  sig { params(member: GameMember).void }
  def apply_status_change(member)
    new_status = params.dig(:game_member, :status) || params[:status]
    return render_roster(alert: "Invalid status.") unless GameMember::STATUSES.include?(new_status)

    member.update!(status: new_status)
    render_roster(notice: "Player status updated.")
  end

  # A status change alters the member's row (its controls) and can empty the
  # roster, so re-render the whole Members section in place plus a toast — no
  # full roster reload. flash.now, not flash: nothing redirects here.
  sig { params(notice: T.nilable(String), alert: T.nilable(String)).void }
  def render_roster(notice: nil, alert: nil)
    flash_now(notice: notice, alert: alert)
    roster = Shared::MemberRosterComponent.new(
      game: GamePresenter.new(game, policy: policy(game), current_user: current_user),
      members: GameMemberRoster.new(game).rows
    )
    render turbo_stream: [ turbo_stream.replace(Shared::MemberRosterComponent::DOM_ID, roster), toast_stream ]
  end
end
