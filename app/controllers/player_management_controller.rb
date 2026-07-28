# typed: true

class PlayerManagementController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_gm!

  sig { void }
  def show
    @members = @game.game_members.where.not(status: "banned").includes(:user)
    @member_display_names = @members.each_with_object({}) { |m, h| h[m.user_id] = UserPresenter.new(m.user).display_name_or_email }
    @pending_invitations = @game.invitations.pending.order(created_at: :desc)
    @invitation = Invitation.new
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def require_gm!
    unless @game.game_master?(current_user)
      redirect_to game_path(@game), alert: "Only the GM can manage players."
    end
  end
end
