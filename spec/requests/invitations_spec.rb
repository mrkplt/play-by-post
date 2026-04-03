require "rails_helper"

RSpec.describe InvitationsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "POST /games/:game_id/player_management/invitations" do
    it "GM can send an invitation" do
      sign_in(gm)
      expect {
        post game_player_management_invitations_path(game),
          params: { invitation: { email: "newplayer@example.com" } }
      }.to change(Invitation, :count).by(1)
      expect(response).to redirect_to(game_player_management_path(game))
    end

    it "player cannot send an invitation" do
      sign_in(player)
      post game_player_management_invitations_path(game),
        params: { invitation: { email: "newplayer@example.com" } }
      expect(response).to redirect_to(game_path(game))
      expect(flash[:alert]).to match(/only the gm/i)
    end

    it "redirects with notice on invalid email" do
      sign_in(gm)
      post game_player_management_invitations_path(game),
        params: { invitation: { email: "not-an-email" } }
      expect(response).to redirect_to(game_player_management_path(game))
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /games/:game_id/player_management/invitations/:id" do
    let!(:invitation) { create(:invitation, game: game) }

    it "GM can cancel an invitation" do
      sign_in(gm)
      expect {
        delete game_player_management_invitation_path(game, invitation)
      }.to change(Invitation, :count).by(-1)
      expect(response).to redirect_to(game_player_management_path(game))
    end

    it "player cannot cancel an invitation" do
      sign_in(player)
      delete game_player_management_invitation_path(game, invitation)
      expect(response).to redirect_to(game_path(game))
    end
  end

  describe "GET /invitations/:token/accept" do
    let(:invitation) { create(:invitation, game: game) }

    it "accepts a valid invitation and signs in the user" do
      get accept_invitation_path(invitation.token)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to match(/welcome/i)
    end

    it "creates the user if they don't exist" do
      expect(User.find_by(email: invitation.email)).to be_nil
      expect {
        get accept_invitation_path(invitation.token)
      }.to change(User, :count).by(1)
    end

    it "updates last_login_at via Warden callback" do
      user = create(:user, :with_profile, email: invitation.email)
      user.user_profile.update!(last_login_at: 1.hour.ago)
      expect {
        get accept_invitation_path(invitation.token)
      }.to change { user.user_profile.reload.last_login_at }
    end

    it "redirects with alert for an invalid token" do
      get accept_invitation_path("invalid-token")
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/invalid/i)
    end

    it "redirects with alert for an already accepted invitation" do
      invitation.accept!
      get accept_invitation_path(invitation.token)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/invalid/i)
    end
  end
end
