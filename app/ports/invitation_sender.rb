# typed: strict

module Ports
  module InvitationSender
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(invitation: Invitation).void }
    def send_invite(invitation:); end
  end
end
