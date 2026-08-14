# typed: strict

class InvitationMailer < ApplicationMailer
  extend T::Sig

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.invitation_mailer.invite.subject
  #
  sig { params(invitation: Invitation).returns(Mail::Message) }
  def invite(invitation)
    game = T.must(invitation.game)
    @invitation_presenter = T.let(
      InvitationPresenter.new(invitation, accept_url: accept_invitation_url(token: invitation.token)),
      T.nilable(InvitationPresenter)
    )
    @game_presenter = T.let(GamePresenter.new(game), T.nilable(GamePresenter))

    mail(
      to: invitation.email,
      subject: "You've been invited to join #{game.name}"
    )
  end
end
