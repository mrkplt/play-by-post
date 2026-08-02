# typed: true

class GameMembersController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_gm!
  before_action :set_member, only: :update
  before_action :require_manageable_member!, only: :update
  after_action :verify_authorized

  sig { void }
  def update
    authorize @member

    new_status = params.dig(:game_member, :status) || params[:status]
    unless GameMember::STATUSES.include?(new_status)
      redirect_to game_player_management_path(@game), alert: "Invalid status."
      return
    end

    @member.update!(status: new_status)
    redirect_to game_player_management_path(@game), notice: "Player status updated."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def set_member
    @member = @game.game_members.find(params[:id])
  end

  # The GM's own membership is not modifiable — the rule lives in
  # GameMemberPolicy#update?; this surfaces its specific message.
  sig { void }
  def require_manageable_member!
    return if policy(@member).update?

    redirect_to game_player_management_path(@game), alert: "Cannot change GM status."
  end

  sig { void }
  def require_gm!
    unless policy(@game).update?
      redirect_to game_path(@game), alert: "Only the GM can manage players."
    end
  end
end
