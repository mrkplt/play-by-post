require "rails_helper"

RSpec.describe FeedsController, type: :request do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game, name: "Alpha Campaign") }
  let(:other_game) { create(:game, name: "Beta Campaign") }

  def summary_in(a_game, body:)
    scene = create(:scene, :resolved, game: a_game)
    create(:scene_summary, scene: scene, body: body)
  end

  describe "GET /feeds" do
    before { create(:game_member, game: game, user: user) }

    it "renders the token's game summaries" do
      summary = summary_in(game, body: "Alpha scene recap")
      token = create(:rss_token, user: user, game: game)

      get feeds_path(token: token.token)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/rss+xml")
      expect(response.body).to include(summary.body)
    end

    it "establishes no session — a valid feed request cannot be traded for auth" do
      token = create(:rss_token, user: user, game: game)

      # A valid feed read must NOT sign the token's owner in. Otherwise a brute-
      # forced token could bootstrap a session and impersonate the user in-app.
      get feeds_path(token: token.token)
      expect(response).to have_http_status(:ok)

      # Same session, a protected in-app route: still unauthenticated.
      get profile_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not set a Warden session on the response" do
      token = create(:rss_token, user: user, game: game)

      get feeds_path(token: token.token)

      expect(request.env["warden"].user).to be_nil
    end

    it "marks the token-bearing response uncacheable by shared caches" do
      token = create(:rss_token, user: user, game: game)

      get feeds_path(token: token.token)

      expect(response.headers["Cache-Control"]).to include("no-store")
    end

    it "renders only the token's game, not other games" do
      create(:game_member, game: other_game, user: user)
      mine = summary_in(game, body: "Alpha scene recap")
      elsewhere = summary_in(other_game, body: "Beta scene recap")
      token = create(:rss_token, user: user, game: game)

      get feeds_path(token: token.token)

      expect(response.body).to include(mine.body)
      expect(response.body).not_to include(elsewhere.body)
    end

    it "returns 401 when the owner is no longer an active member" do
      game.game_members.find_by(user: user).update!(status: "removed")
      # A removed member can still view (GamePolicy#show?), so use a banned one.
      banned = create(:user, :with_profile)
      create(:game_member, :banned, game: game, user: banned)
      token = create(:rss_token, user: banned, game: game)

      get feeds_path(token: token.token)

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a blank token" do
      get feeds_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for an unknown token" do
      get feeds_path(token: "bogus-token")
      expect(response).to have_http_status(:unauthorized)
    end

    it "excludes private scenes" do
      private_scene = create(:scene, :resolved, game: game, private: true)
      hidden = create(:scene_summary, scene: private_scene, body: "Private recap")
      token = create(:rss_token, user: user, game: game)

      get feeds_path(token: token.token)

      expect(response.body).not_to include(hidden.body)
    end

    it "excludes unresolved scenes" do
      unresolved = create(:scene, game: game)
      hidden = create(:scene_summary, scene: unresolved, body: "Unresolved recap")
      token = create(:rss_token, user: user, game: game)

      get feeds_path(token: token.token)

      expect(response.body).not_to include(hidden.body)
    end

    it "orders items by most recently resolved first" do
      older = create(:scene, :resolved, game: game, resolved_at: 3.days.ago)
      newer = create(:scene, :resolved, game: game, resolved_at: 1.day.ago)
      older_summary = create(:scene_summary, scene: older, body: "Older recap")
      newer_summary = create(:scene_summary, scene: newer, body: "Newer recap")
      token = create(:rss_token, user: user, game: game)

      get feeds_path(token: token.token)

      expect(response.body.index(newer_summary.body))
        .to be < response.body.index(older_summary.body)
    end
  end
end
