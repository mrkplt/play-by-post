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
      redirect_to_roster notice: "Invitation sent to #{invitation.email}."
    else
      redirect_to_roster alert: invitation.errors.full_messages.join(", ")
    end
  end

  sig { void }
  def destroy
    invitation = game.invitations.find(params[:id])
    authorize invitation
    invitation.destroy
    redirect_to_roster notice: "Invitation cancelled."
  end

  sig { void }
  def resend
    invitation = game.invitations.find(params[:id])
    authorize invitation, :resend?
    InvitationMailer.invite(invitation).deliver_later
    redirect_to_roster notice: "Invitation resent to #{invitation.email}."
  end

  sig { void }
  def accept
    invitation = Invitation.find_by(token: params[:token])
    return redirect_to root_path, alert: "This invitation is invalid or has already been used." unless usable?(invitation)

    accept_invitation(T.must(invitation))
  end

  private

  # Used only internally (associations, redirect targets) — never read by a
  # template (this controller renders no views of its own), so it is not an
  # ivar.
  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:game_id])
  end

  sig { params(notice: T.nilable(String), alert: T.nilable(String)).void }
  def redirect_to_roster(notice: nil, alert: nil)
    redirect_to game_path(game, anchor: "roster"), notice: notice, alert: alert
  end

  sig { params(invitation: T.nilable(Invitation)).returns(T::Boolean) }
  def usable?(invitation)
    invitation.present? && !invitation.accepted?
  end

  sig { params(invitation: Invitation).void }
  def accept_invitation(invitation)
    user = User.find_or_create_by!(email: invitation.email)
    invitation.accept_for!(user)
    sign_in(user)

    accepted_game = T.must(invitation.game)
    redirect_to game_path(accepted_game), notice: "Welcome! You've joined #{accepted_game.name}."
  end
end
