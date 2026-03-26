require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "invite" do
    let(:invitation) { create(:invitation) }
    let(:mail) { InvitationMailer.invite(invitation) }

    it "renders the headers" do
      expect(mail.subject).to include(invitation.game.name)
      expect(mail.to).to eq([ invitation.email ])
    end

    it "renders the accept link in the body" do
      expect(mail.body.encoded).to include("accept")
    end
  end
end
