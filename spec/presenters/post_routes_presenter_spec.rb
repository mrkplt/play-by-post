require "rails_helper"

RSpec.describe PostRoutesPresenter do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene) }
  let(:post) { build_stubbed(:post, scene: scene) }
  let(:urls) { double("url_helpers") }

  subject(:presenter) { described_class.new(post, game: game, scene: scene, urls: urls) }

  describe "#mark_read_url" do
    it "builds the mark-read path from the injected game/scene/url_helpers" do
      allow(urls).to receive(:mark_read_game_scene_post_path).with(game, scene, post).and_return("/mark_read")
      expect(presenter.mark_read_url).to eq("/mark_read")
    end
  end

  describe "#edit_url" do
    it "builds the edit path from the injected game/scene/url_helpers" do
      allow(urls).to receive(:edit_game_scene_post_path).with(game, scene, post).and_return("/edit")
      expect(presenter.edit_url).to eq("/edit")
    end
  end

  describe "with no scene supplied" do
    subject(:presenter) { described_class.new(post, game: game, urls: urls) }

    it "falls back to the post's own scene" do
      allow(urls).to receive(:edit_game_scene_post_path).with(game, scene, post).and_return("/edit")
      expect(presenter.edit_url).to eq("/edit")
    end
  end
end
