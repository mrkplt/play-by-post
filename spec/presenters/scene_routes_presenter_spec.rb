require "rails_helper"

RSpec.describe SceneRoutesPresenter do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene) }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(scene, game: game, urls: urls) }

  describe "#resolve_path" do
    it "builds the scene's resolve path from the injected game and url_helpers" do
      allow(urls).to receive(:resolve_game_scene_path).with(game, scene).and_return("/games/1/scenes/2/resolve")
      expect(presenter.resolve_path).to eq("/games/1/scenes/2/resolve")
    end
  end

  describe "#save_draft_url" do
    it "resolves the save-draft URL against its own game and scene" do
      allow(urls).to receive(:save_draft_game_scene_posts_path)
        .with(game, scene).and_return("/games/1/scenes/2/posts/save_draft")
      expect(presenter.save_draft_url).to eq("/games/1/scenes/2/posts/save_draft")
    end
  end

  describe "#discard_draft_url" do
    it "resolves the discard-draft URL against its own game and scene" do
      allow(urls).to receive(:discard_draft_game_scene_posts_path)
        .with(game, scene).and_return("/games/1/scenes/2/posts/discard_draft")
      expect(presenter.discard_draft_url).to eq("/games/1/scenes/2/posts/discard_draft")
    end
  end
end
