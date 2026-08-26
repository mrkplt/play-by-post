require "rails_helper"

RSpec.describe GameControlRowPresenter do
  let(:game) { build_stubbed(:game, name: "Ashfall Reaches") }
  let(:urls) { double("urls") }

  def row(feed_token: nil, api_token: nil, contributed: Set.new)
    described_class.new(
      game, feed_token: feed_token, api_token: api_token, contributed_features: contributed, urls: urls)
  end

  it "exposes the game name" do
    expect(row.name).to eq("Ashfall Reaches")
  end

  describe "#feed" do
    it "wraps the game and the rss token in a GameFeedRowPresenter" do
      token = build_stubbed(:api_token, game: game, scope: "rss")
      feed = row(feed_token: token).feed

      expect(feed).to be_a(GameFeedRowPresenter)
      expect(feed.token?).to be(true)
    end

    it "reports no token when none was supplied" do
      expect(row.feed.token?).to be(false)
    end

    it "memoizes across calls" do
      built = row
      expect(built.feed).to equal(built.feed)
    end
  end

  describe "#api" do
    it "wraps the game and the api token in an ApiTokenRowPresenter" do
      token = build_stubbed(:api_token, game: game, scope: "api", token: "raw")
      api = row(api_token: token).api

      expect(api).to be_a(ApiTokenRowPresenter)
      expect(api.token?).to be(true)
      expect(api.secret_value).to eq("raw")
    end

    it "memoizes across calls" do
      built = row
      expect(built.api).to equal(built.api)
    end
  end

  describe "#ai_cells" do
    before do
      allow(urls).to receive(:game_key_contributions_path).and_return("/create")
      allow(urls).to receive(:game_key_contribution_path).and_return("/destroy")
    end

    it "marks a contributed feature Offered" do
      cells = row(contributed: Set.new([ "scene_summary" ])).ai_cells
      expect(cells.first).to be_a(Shared::GameControlsComponent::Offered)
    end

    it "marks an uncontributed feature Available" do
      cells = row.ai_cells
      expect(cells.first).to be_a(Shared::GameControlsComponent::Available)
    end
  end
end
