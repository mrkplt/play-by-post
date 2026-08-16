require "rails_helper"

RSpec.describe SceneSummaryRoutesPresenter do
  let(:game) { build_stubbed(:game, id: 7) }
  let(:scene) { build_stubbed(:scene, id: 42) }
  let(:summary) { build_stubbed(:scene_summary) }
  let(:urls) { double("urls") }

  before { allow(summary).to receive(:scene).and_return(scene) }

  subject(:presenter) { described_class.new(summary, game: game, urls: urls) }

  describe "#scene_path" do
    it "builds the scene's show path from the injected game and url_helpers" do
      allow(urls).to receive(:game_scene_path).with(game, scene).and_return("/games/7/scenes/42")
      expect(presenter.scene_path).to eq("/games/7/scenes/42")
    end
  end

  describe "#edit_path" do
    it "builds the summary's edit path from the injected game and url_helpers" do
      allow(urls).to receive(:edit_game_scene_scene_summary_path).with(game, scene)
        .and_return("/games/7/scenes/42/scene_summary/edit")
      expect(presenter.edit_path).to eq("/games/7/scenes/42/scene_summary/edit")
    end
  end

  describe "#submit_path" do
    it "builds the summary's resource path from the injected game and url_helpers" do
      allow(urls).to receive(:game_scene_scene_summary_path).with(game, scene)
        .and_return("/games/7/scenes/42/scene_summary")
      expect(presenter.submit_path).to eq("/games/7/scenes/42/scene_summary")
    end
  end

  describe "#scene_url" do
    it "builds the scene's absolute URL from the injected game and url_helpers" do
      allow(urls).to receive(:game_scene_url).with(game, scene).and_return("https://example.com/games/7/scenes/42")
      expect(presenter.scene_url).to eq("https://example.com/games/7/scenes/42")
    end
  end
end
