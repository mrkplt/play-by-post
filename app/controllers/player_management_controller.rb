class PlayerManagementController < ApplicationController
  before_action :set_game
  before_action :require_gm!

  def show
    @members = @game.game_members.where.not(status: "banned").includes(:user)
    @pending_invitations = @game.invitations.pending.order(created_at: :desc)
    @invitation = Invitation.new
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
