require "rails_helper"

RSpec.describe Games::KeyContributionsController, type: :request do
  let(:game) { create(:game) }
  let(:member) { create(:user, :with_profile) }

  before do
    create(:game_member, game: game, user: member)
    allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
  end

  describe "POST /games/:game_id/key_contributions" do
    it "creates the member's own authorization for the feature" do
      sign_in member

      expect {
        post game_key_contributions_path(game), params: { feature: "scene_summary" }
      }.to change { GameKeyAuthorization.where(game: game, user: member, feature: "scene_summary").count }.by(1)

      expect(response).to redirect_to(profile_path)
    end

    it "denies a non-member" do
      outsider = create(:user, :with_profile)
      sign_in outsider

      expect {
        post game_key_contributions_path(game), params: { feature: "scene_summary" }
      }.not_to change(GameKeyAuthorization, :count)
    end

    it "redirects with the validation error when the member has no key to offer" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(false)
      sign_in member

      expect {
        post game_key_contributions_path(game), params: { feature: "scene_summary" }
      }.not_to change(GameKeyAuthorization, :count)

      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("must have a BYOK OpenRouter key")
    end
  end

  describe "DELETE /games/:game_id/key_contributions/:feature" do
    it "removes the member's own authorization" do
      create(:game_key_authorization, game: game, user: member, feature: "scene_summary")
      sign_in member

      expect {
        delete game_key_contribution_path(game, "scene_summary")
      }.to change { GameKeyAuthorization.where(game: game, user: member).count }.by(-1)

      expect(response).to redirect_to(profile_path)
    end
  end
end
