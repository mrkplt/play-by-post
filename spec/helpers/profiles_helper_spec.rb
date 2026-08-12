require "rails_helper"

RSpec.describe ProfilesHelper, type: :helper do
  describe "#rss_feed_url" do
    it "returns nil when there is no token" do
      expect(helper.rss_feed_url(nil)).to be_nil
    end

    it "builds the /feeds URL carrying the token" do
      token = build_stubbed(:rss_token, token: "abc123")
      expect(helper.rss_feed_url(token)).to eq(helper.feeds_url(token: "abc123"))
    end
  end

  describe "#rss_scope_param" do
    it "carries the game_id for a game scope" do
      game = build_stubbed(:game)
      expect(helper.rss_scope_param(game)).to eq(game_id: game.id)
    end
  end

  describe "#profile_rss_scopes", db: true do
    it "returns the user's RSS scopes, one per game" do
      user = create(:user)
      create(:game_member, game: create(:game, name: "Alpha"), user: user)

      labels = helper.profile_rss_scopes(user).map(&:label)

      expect(labels).to eq([ "Alpha" ])
    end
  end
end
