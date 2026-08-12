require "rails_helper"

RSpec.describe FeedsHelper, type: :helper do
  let(:game) { build_stubbed(:game, name: "Alpha") }
  let(:other) { build_stubbed(:game, name: "Beta") }
  let(:scene) { build_stubbed(:scene, game: game, title: "The Reckoning") }

  describe "#feed_channel_title" do
    it "names all campaigns for an account-level feed" do
      expect(helper.feed_channel_title([ game, other ], account_level: true))
        .to eq("All Campaigns — Campaign Log")
    end

    it "names the single game for a game-level feed" do
      expect(helper.feed_channel_title([ game ], account_level: false))
        .to eq("Alpha — Campaign Log")
    end
  end

  describe "#feed_channel_description" do
    it "describes all campaigns for an account-level feed" do
      expect(helper.feed_channel_description([ game ], account_level: true))
        .to eq("Scene summaries across all your campaigns")
    end

    it "describes the single game for a game-level feed" do
      expect(helper.feed_channel_description([ game ], account_level: false))
        .to eq("Scene summaries for Alpha")
    end
  end

  describe "#feed_channel_link" do
    it "links to the first game's campaign log" do
      expect(helper.feed_channel_link([ game, other ]))
        .to eq(helper.game_scene_summaries_url(game))
    end
  end

  describe "#feed_item_title" do
    it "prefixes the game name for an account-level feed" do
      expect(helper.feed_item_title(scene, game, account_level: true))
        .to eq("[Alpha] The Reckoning")
    end

    it "uses the bare scene title for a game-level feed" do
      expect(helper.feed_item_title(scene, game, account_level: false))
        .to eq("The Reckoning")
    end
  end
end
