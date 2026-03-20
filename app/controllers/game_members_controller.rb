class GameMembersController < ApplicationController
  before_action :set_game
  before_action :require_gm!

  def update
    @member = @game.game_members.find(params[:id])

    if @member.game_master?
      redirect_to game_player_management_path(@game), alert: "Cannot change GM status."
      return
    end

    new_status = params.dig(:game_member, :status) || params[:status]
    unless GameMember::STATUSES.include?(new_status)
      redirect_to game_player_management_path(@game), alert: "Invalid status."
      return
    end

    @member.update!(status: new_status)
    redirect_to game_player_management_path(@game), notice: "Player status updated."
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def require_gm!
    unless @game.game_master?(current_user)
      redirect_to game_path(@game), alert: "Only the GM can manage players."
    end
  end
end
