require "rails_helper"

RSpec.describe GameFeedRowPresenter do
  let(:game) { build_stubbed(:game, name: "Ashfall Reaches") }
  let(:urls) { double("urls") }

  describe "#name" do
    it "delegates to the game" do
      presenter = described_class.new(game, urls: urls)
      expect(presenter.name).to eq("Ashfall Reaches")
    end
  end

  describe "#game_id" do
    it "delegates to the game" do
      presenter = described_class.new(game, urls: urls)
      expect(presenter.game_id).to eq(game.id)
    end
  end

  describe "#token?" do
    it "is false with no token" do
      expect(described_class.new(game, token: nil, urls: urls).token?).to be(false)
    end

    it "is true with a token" do
      token = build_stubbed(:api_token, game: game, scope: "rss")
      expect(described_class.new(game, token: token, urls: urls).token?).to be(true)
    end
  end

  describe "#feed_url" do
    it "builds the feed URL from the token value" do
      token = build_stubbed(:api_token, game: game, scope: "rss", token: "sekret")
      allow(urls).to receive(:rss_feed_url).with(token: "sekret").and_return("https://example.com/rss/feed?token=sekret")
      presenter = described_class.new(game, token: token, urls: urls)
      expect(presenter.feed_url).to eq("https://example.com/rss/feed?token=sekret")
    end
  end

  describe "#revoke_path" do
    it "targets the token's destroy route" do
      token = build_stubbed(:api_token, game: game, scope: "rss")
      allow(urls).to receive(:profile_api_token_path).with(token).and_return("/profile/api_tokens/#{token.id}")
      presenter = described_class.new(game, token: token, urls: urls)
      expect(presenter.revoke_path).to eq("/profile/api_tokens/#{token.id}")
    end
  end

  describe "#create_path" do
    it "targets the tokens collection route" do
      allow(urls).to receive(:profile_api_tokens_path).and_return("/profile/api_tokens")
      presenter = described_class.new(game, urls: urls)
      expect(presenter.create_path).to eq("/profile/api_tokens")
    end
  end
end
