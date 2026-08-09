require "rails_helper"

RSpec.describe Shared::InvitePanelComponent, type: :component do
  let(:game) { build_stubbed(:game) }

  context "with no pending invitations" do
    subject(:component) { described_class.new(game: game, pending_invitations: []) }

    it "pending? returns false" do
      expect(component.pending?).to be(false)
    end

    it "renders the invite form" do
      render_inline(component)
      expect(page).to have_text("Invite a Player")
      expect(page).to have_css("input[name='invitation[email]']")
      expect(page).to have_button("Invite")
    end

    it "does not render the pending invitations section" do
      render_inline(component)
      expect(page).not_to have_text("Pending Invitations")
    end
  end

  context "with pending invitations" do
    let(:invitation) { build_stubbed(:invitation, game: game, email: "pending@example.com", created_at: 2.hours.ago) }
    subject(:component) { described_class.new(game: game, pending_invitations: [ invitation ]) }

    it "pending? returns true" do
      expect(component.pending?).to be(true)
    end

    it "renders each pending invitation with resend and cancel controls" do
      render_inline(component)
      expect(page).to have_text("Pending Invitations")
      expect(page).to have_text("pending@example.com")
      expect(page).to have_button("Resend")
      expect(page).to have_button("Cancel")
    end

    it "labels each pending invitation with how long ago it was sent" do
      render_inline(component)
      expect(page).to have_text("Sent about 2 hours ago")
    end

    it "last? is true only for the final index" do
      expect(component.last?(0)).to be(true)
      expect(component.last?(1)).to be(false)
    end

    it "posts the invite form to the game's invitations collection" do
      render_inline(component)
      expect(page).to have_css("form[action='/games/#{game.id}/player_management/invitations']")
    end

    it "targets the invitation member route for cancellation" do
      render_inline(component)
      expect(page).to have_css("form[action='/games/#{game.id}/player_management/invitations/#{invitation.id}']")
    end

    it "targets the invitation resend route for resending" do
      render_inline(component)
      expect(page).to have_css("form[action='/games/#{game.id}/player_management/invitations/#{invitation.id}/resend']")
    end
  end
end
