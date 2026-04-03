# typed: true

class InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[accept]

  before_action :set_game, except: %i[accept]
  before_action :require_gm!, except: %i[accept]

  def create
    @invitation = @game.invitations.new(email: params[:invitation][:email], invited_by: current_user)

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to game_player_management_path(@game), notice: "Invitation sent to #{@invitation.email}."
    else
      redirect_to game_player_management_path(@game), alert: @invitation.errors.full_messages.join(", ")
    end
  end

  def destroy
    invitation = @game.invitations.find(params[:id])
    invitation.destroy
    redirect_to game_player_management_path(@game), notice: "Invitation cancelled."
  end

  def accept
    @invitation = Invitation.find_by(token: params[:token])

    if @invitation.nil? || @invitation.accepted?
      redirect_to root_path, alert: "This invitation is invalid or has already been used."
      return
    end

    user = User.find_or_create_by!(email: @invitation.email)
    @invitation.game.game_members.find_or_create_by!(user: user, role: "player", status: "active")
    @invitation.accept!

    sign_in(user)
    redirect_to game_path(@invitation.game), notice: "Welcome! You've joined #{@invitation.game.name}."
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def require_gm!
    unless @game.game_master?(current_user)
      redirect_to game_path(@game), alert: "Only the GM can manage invitations."
    end
  end
end
