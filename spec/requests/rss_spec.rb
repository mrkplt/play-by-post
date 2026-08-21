require "rails_helper"

RSpec.describe RssController, type: :request do
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let(:token) { create(:api_token, user: player, game: game) }

  before do
    create(:game_member, :game_master, game: game, user: gm)
    create(:game_member, game: game, user: player)
  end

  describe "GET /rss/feed" do
    it "returns the feed for an active member with a valid token", :db do
      resolved = create(:scene, :resolved, game: game, private: false)
      summary = create(:scene_summary, scene: resolved)

      get "/rss/feed", params: { token: token.token }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/rss+xml")
      expect(response.body).to include(summary.body)
      expect(response.body).to include("#{game.name} — Campaign Log")
    end

    it "accepts the token via an Authorization: Bearer header", :db do
      get "/rss/feed", headers: { "Authorization" => "Bearer #{token.token}" }
      expect(response).to have_http_status(:ok)
    end

    it "accepts a lowercase bearer scheme (RFC 7235 case-insensitive)", :db do
      get "/rss/feed", headers: { "Authorization" => "bearer #{token.token}" }
      expect(response).to have_http_status(:ok)
    end

    it "serves each game's own summaries only — a token for game A never leaks game B", :db do
      other_game = create(:game)
      create(:game_member, game: other_game, user: player)
      other_resolved = create(:scene, :resolved, game: other_game, private: false, title: "Elsewhere")
      create(:scene_summary, scene: other_resolved, body: "A summary from the other game.")

      this_resolved = create(:scene, :resolved, game: game, private: false)
      create(:scene_summary, scene: this_resolved, body: "A summary from this game.")

      get "/rss/feed", params: { token: token.token }

      expect(response.body).to include("A summary from this game.")
      expect(response.body).not_to include("A summary from the other game.")
    end

    it "excludes AI-generated summaries when the token user's AI display preference is hidden", :db do
      resolved = create(:scene, :resolved, game: game, private: false)
      ai_summary = create(:scene_summary, :ai_generated, scene: resolved, body: "AI-written recap.")
      hand_scene = create(:scene, :resolved, game: game, private: false)
      hand_written = create(:scene_summary, scene: hand_scene, body: "Hand-written recap.")
      player.user_profile.update!(ai_display_preference: :hidden)

      get "/rss/feed", params: { token: token.token }

      expect(response.body).to include(hand_written.body)
      expect(response.body).not_to include(ai_summary.body)
    end

    it "includes AI-generated summaries when the token user's AI display preference is tagged", :db do
      resolved = create(:scene, :resolved, game: game, private: false)
      ai_summary = create(:scene_summary, :ai_generated, scene: resolved, body: "AI-written recap.")
      player.user_profile.update!(ai_display_preference: :tagged)

      get "/rss/feed", params: { token: token.token }

      expect(response.body).to include(ai_summary.body)
    end

    it "does not include summaries of private scenes", :db do
      private_scene = create(:scene, :resolved, game: game, private: true)
      summary = create(:scene_summary, scene: private_scene)
      get "/rss/feed", params: { token: token.token }
      expect(response.body).not_to include(summary.body)
    end

    it "does not include draft summaries — an unpublished summary never reaches the feed", :db do
      resolved = create(:scene, :resolved, game: game, private: false)
      draft = create(:scene_summary, scene: resolved, body: "A secret work in progress.", draft: true)
      get "/rss/feed", params: { token: token.token }
      expect(response.body).not_to include(draft.body)
    end

    it "returns 401 with no token", :db do
      get "/rss/feed"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for an unknown token", :db do
      get "/rss/feed", params: { token: "bogus" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for a non-rss scope", :db do
      api_token = create(:api_token, user: player, game: game, scope: "api")
      get "/rss/feed", params: { token: api_token.token }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 when the token's user is no longer an active member", :db do
      GameMember.find_by(game: game, user: player).update!(status: "removed")
      get "/rss/feed", params: { token: token.token }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 when the token's user was banned", :db do
      GameMember.find_by(game: game, user: player).update!(status: "banned")
      get "/rss/feed", params: { token: token.token }
      expect(response).to have_http_status(:forbidden)
    end

    it "does not establish a session", :db do
      get "/rss/feed", params: { token: token.token }
      expect(response.headers["Set-Cookie"]).to be_nil
    end
  end
end
