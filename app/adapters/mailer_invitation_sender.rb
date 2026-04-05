# typed: strict

class MailerInvitationSender
  extend T::Sig
  include Ports::InvitationSender

  sig { override.params(invitation: Invitation).void }
  def send_invite(invitation:)
    InvitationMailer.invite(invitation).deliver_later
  end
end
