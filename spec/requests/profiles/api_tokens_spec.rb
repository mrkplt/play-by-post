require "rails_helper"

RSpec.describe Profiles::ApiTokensController, type: :request do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  before { create(:game_member, game: game, user: user) }

  describe "POST /profile/api_tokens" do
    it "creates an rss token for a game the user belongs to", :db do
      sign_in(user)
      expect {
        post profile_api_tokens_path, params: { game_id: game.id, scope: "rss" }
      }.to change(ApiToken, :count).by(1)
      expect(response).to redirect_to(profile_path)
      token = ApiToken.last
      expect(token.user).to eq(user)
      expect(token.game).to eq(game)
      expect(token.scope).to eq("rss")
    end

    it "defaults the scope to rss when omitted", :db do
      sign_in(user)
      post profile_api_tokens_path, params: { game_id: game.id }
      expect(ApiToken.last.scope).to eq("rss")
    end

    it "rotates an existing token instead of creating a second", :db do
      sign_in(user)
      existing = create(:api_token, user: user, game: game, scope: "rss")
      original = existing.token
      expect {
        post profile_api_tokens_path, params: { game_id: game.id, scope: "rss" }
      }.not_to change(ApiToken, :count)
      expect(existing.reload.token).not_to eq(original)
    end

    it "refuses a game the user is not a member of", :db do
      other_game = create(:game)
      sign_in(user)
      expect {
        post profile_api_tokens_path, params: { game_id: other_game.id, scope: "rss" }
      }.not_to change(ApiToken, :count)
      expect(flash[:alert]).to be_present
    end

    it "refuses a game the user is banned from", :db do
      banned_game = create(:game)
      create(:game_member, :banned, game: banned_game, user: user)
      sign_in(user)
      expect {
        post profile_api_tokens_path, params: { game_id: banned_game.id, scope: "rss" }
      }.not_to change(ApiToken, :count)
      expect(flash[:alert]).to be_present
    end

    it "refuses an unknown scope", :db do
      sign_in(user)
      expect {
        post profile_api_tokens_path, params: { game_id: game.id, scope: "wat" }
      }.not_to change(ApiToken, :count)
      expect(flash[:alert]).to be_present
    end

    it "redirects unauthenticated users", :db do
      post profile_api_tokens_path, params: { game_id: game.id }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /profile/api_tokens/:id" do
    it "destroys the user's own token", :db do
      sign_in(user)
      token = create(:api_token, user: user, game: game)
      expect {
        delete profile_api_token_path(token)
      }.to change(ApiToken, :count).by(-1)
      expect(response).to redirect_to(profile_path)
    end

    it "does not destroy another user's token", :db do
      other = create(:user, :with_profile)
      other_game = create(:game)
      create(:game_member, game: other_game, user: other)
      token = create(:api_token, user: other, game: other_game)
      sign_in(user)
      expect {
        delete profile_api_token_path(token)
      }.not_to change(ApiToken, :count)
    end

    it "redirects unauthenticated users", :db do
      token = create(:api_token, user: user, game: game)
      delete profile_api_token_path(token)
      expect(response).to have_http_status(:redirect)
    end
  end
end
