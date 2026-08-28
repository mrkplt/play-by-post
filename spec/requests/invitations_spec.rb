require "rails_helper"

RSpec.describe InvitationsController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  it_behaves_like "a slug-addressed game action" do
    let(:signed_in_user) { gm }
    def perform_request(game_id) = post game_player_management_invitations_path(game_id)
  end

  describe "POST /games/:game_id/player_management/invitations" do
    it "GM can send an invitation" do
      sign_in(gm)
      expect {
        post game_player_management_invitations_path(game),
          params: { invitation: { email: "newplayer@example.com" } }
      }.to change(Invitation, :count).by(1)
      # In place: re-render the invite panel + toast, no full reload.
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Shared::InvitePanelComponent::DOM_ID)
    end

    it "player cannot send an invitation" do
      sign_in(player)
      post game_player_management_invitations_path(game),
        params: { invitation: { email: "newplayer@example.com" } }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end

    it "redirects with notice on invalid email" do
      sign_in(gm)
      post game_player_management_invitations_path(game),
        params: { invitation: { email: "not-an-email" } }
      expect(response).to have_http_status(:ok)
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
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Shared::InvitePanelComponent::DOM_ID)
    end

    it "player cannot cancel an invitation" do
      sign_in(player)
      delete game_player_management_invitation_path(game, invitation)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end
  end

  describe "POST /games/:game_id/player_management/invitations/:id/resend" do
    let!(:invitation) { create(:invitation, game: game) }

    it "GM can resend a pending invitation without creating a new one" do
      sign_in(gm)
      original_token = invitation.token
      expect {
        post resend_game_player_management_invitation_path(game, invitation)
      }.not_to change(Invitation, :count)
      expect(invitation.reload.token).to eq(original_token)
      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to match(/resent/i)
    end

    it "sends the invitation email again" do
      sign_in(gm)
      expect {
        post resend_game_player_management_invitation_path(game, invitation)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq([ invitation.email ])
    end

    it "player cannot resend an invitation" do
      sign_in(player)
      post resend_game_player_management_invitation_path(game, invitation)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
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
