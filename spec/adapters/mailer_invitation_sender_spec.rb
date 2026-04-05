# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailerInvitationSender do
  subject(:adapter) { described_class.new }

  let(:invitation) { create(:invitation) }
  let(:delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: nil) }

  describe "#send_invite" do
    it "delivers an invite email later" do
      allow(InvitationMailer).to receive(:invite).with(invitation).and_return(delivery)
      adapter.send_invite(invitation: invitation)
      expect(delivery).to have_received(:deliver_later)
    end
  end
end
