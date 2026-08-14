# typed: strict

class InvitationsController < ApplicationController
  extend T::Sig

  skip_before_action :authenticate_user!, only: %i[accept]

  after_action :verify_authorized, except: %i[accept]

  sig { void }
  def create
    invitation = game.invitations.new(email: params[:invitation][:email], invited_by: current_user)
    authorize invitation

    if invitation.save
      InvitationMailer.invite(invitation).deliver_later
      redirect_to game_path(game, anchor: "roster"), notice: "Invitation sent to #{invitation.email}."
    else
      redirect_to game_path(game, anchor: "roster"), alert: invitation.errors.full_messages.join(", ")
    end
  end

  sig { void }
  def destroy
    invitation = game.invitations.find(params[:id])
    authorize invitation
    invitation.destroy
    redirect_to game_path(game, anchor: "roster"), notice: "Invitation cancelled."
  end

  sig { void }
  def resend
    invitation = game.invitations.find(params[:id])
    authorize invitation, :resend?
    InvitationMailer.invite(invitation).deliver_later
    redirect_to game_path(game, anchor: "roster"), notice: "Invitation resent to #{invitation.email}."
  end

  sig { void }
  def accept
    invitation = Invitation.find_by(token: params[:token])

    if invitation.nil? || invitation.accepted?
      redirect_to root_path, alert: "This invitation is invalid or has already been used."
      return
    end

    game = T.must(invitation.game)
    user = User.find_or_create_by!(email: invitation.email)
    game.game_members.find_or_create_by!(user: user, role: "player", status: "active")
    invitation.accept!

    sign_in(user)
    redirect_to game_path(game), notice: "Welcome! You've joined #{game.name}."
  end

  private

  # Used only internally (associations, redirect targets) — never read by a
  # template (this controller renders no views of its own), so it is not an
  # ivar.
  sig { returns(Game) }
  def game
    Game.find(params[:game_id])
  end
end
