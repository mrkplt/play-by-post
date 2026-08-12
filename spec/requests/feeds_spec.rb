require "rails_helper"

RSpec.describe FeedsController, type: :request do
  let(:user) { create(:user, :with_profile) }
  let(:game_a) { create(:game, name: "Alpha Campaign") }
  let(:game_b) { create(:game, name: "Beta Campaign") }

  def summary_in(game, body:)
    scene = create(:scene, :resolved, game: game)
    create(:scene_summary, scene: scene, body: body)
  end

  describe "GET /feeds" do
    context "with a game-level token" do
      before { create(:game_member, game: game_a, user: user) }

      it "renders only that game's summaries" do
        summary_a = summary_in(game_a, body: "Alpha scene recap")
        create(:game_member, game: game_b, user: user)
        summary_b = summary_in(game_b, body: "Beta scene recap")
        token = create(:rss_token, user: user, game: game_a)

        get feeds_path(token: token.token)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/rss+xml")
        expect(response.body).to include(summary_a.body)
        expect(response.body).not_to include(summary_b.body)
      end

      it "returns 401 when the owner is no longer an active member" do
        member = game_a.game_members.find_by(user: user)
        member.update!(status: "removed")
        token = create(:rss_token, user: user, game: game_a)

        get feeds_path(token: token.token)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an account-level token" do
      before do
        create(:game_member, game: game_a, user: user)
        create(:game_member, game: game_b, user: user)
      end

      it "aggregates summaries across every game the user is an active member of" do
        summary_a = summary_in(game_a, body: "Alpha scene recap")
        summary_b = summary_in(game_b, body: "Beta scene recap")
        token = create(:rss_token, user: user, game: nil)

        get feeds_path(token: token.token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(summary_a.body)
        expect(response.body).to include(summary_b.body)
      end

      it "excludes games the user is not an active member of" do
        other_game = create(:game, name: "Gamma Campaign")
        secret = summary_in(other_game, body: "Gamma scene recap")
        token = create(:rss_token, user: user, game: nil)

        get feeds_path(token: token.token)

        expect(response.body).not_to include(secret.body)
      end

      it "returns 401 when the user is an active member of no games" do
        loner = create(:user, :with_profile)
        token = create(:rss_token, user: loner, game: nil)

        get feeds_path(token: token.token)

        expect(response).to have_http_status(:unauthorized)
      end
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
      create(:game_member, game: game_a, user: user)
      private_scene = create(:scene, :resolved, game: game_a, private: true)
      hidden = create(:scene_summary, scene: private_scene, body: "Private recap")
      token = create(:rss_token, user: user, game: game_a)

      get feeds_path(token: token.token)

      expect(response.body).not_to include(hidden.body)
    end

    it "excludes unresolved scenes" do
      create(:game_member, game: game_a, user: user)
      unresolved = create(:scene, game: game_a)
      hidden = create(:scene_summary, scene: unresolved, body: "Unresolved recap")
      token = create(:rss_token, user: user, game: game_a)

      get feeds_path(token: token.token)

      expect(response.body).not_to include(hidden.body)
    end

    it "orders items by most recently resolved first" do
      create(:game_member, game: game_a, user: user)
      older = create(:scene, :resolved, game: game_a, resolved_at: 3.days.ago)
      newer = create(:scene, :resolved, game: game_a, resolved_at: 1.day.ago)
      older_summary = create(:scene_summary, scene: older, body: "Older recap")
      newer_summary = create(:scene_summary, scene: newer, body: "Newer recap")
      token = create(:rss_token, user: user, game: game_a)

      get feeds_path(token: token.token)

      expect(response.body.index(newer_summary.body))
        .to be < response.body.index(older_summary.body)
    end
  end
end
