require "rails_helper"

RSpec.describe SceneCardPresenter do
  let(:scene) { build_stubbed(:scene) }
  let(:scene_presenter) { ScenePresenter.new(scene) }

  subject(:presenter) { described_class.new(scene_presenter) }

  describe "#parent_scene?" do
    it "is false when the scene has no parent" do
      allow(scene).to receive(:parent_scene).and_return(nil)
      expect(presenter.parent_scene?).to be(false)
    end

    it "is true when the scene has a parent" do
      allow(scene).to receive(:parent_scene).and_return(build_stubbed(:scene))
      expect(presenter.parent_scene?).to be(true)
    end
  end

  describe "#parent_scene_presenter" do
    it "wraps the parent scene" do
      parent = build_stubbed(:scene)
      allow(scene).to receive(:parent_scene).and_return(parent)

      result = presenter.parent_scene_presenter
      expect(result).to be_a(ScenePresenter)
      expect(result.model).to eq(parent)
    end
  end

  describe "#child_scenes_in" do
    it "returns only children belonging to the given game, wrapped as presenters" do
      game = build_stubbed(:game)
      other_game = build_stubbed(:game)
      game_presenter = GamePresenter.new(game, policy: instance_double(GamePolicy))
      matching_child = build_stubbed(:scene, game_id: game.id)
      other_child = build_stubbed(:scene, game_id: other_game.id)
      allow(scene).to receive(:child_scenes).and_return([ matching_child, other_child ])

      result = presenter.child_scenes_in(game_presenter)
      expect(result.length).to eq(1)
      expect(result.first).to be_a(ScenePresenter)
      expect(result.first.model).to eq(matching_child)
    end
  end
end
