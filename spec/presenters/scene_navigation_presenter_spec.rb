require "rails_helper"

RSpec.describe SceneNavigationPresenter do
  let(:scene) { build_stubbed(:scene, id: 2) }
  let(:scene_presenter) { ScenePresenter.new(scene) }
  let(:game) { build_stubbed(:game, id: 1) }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(scene_presenter, game: game, urls: urls) }

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

  describe "#parent_scene_title" do
    it "returns the parent scene's title" do
      parent = build_stubbed(:scene, title: "The Fall of Vex")
      allow(scene).to receive(:parent_scene).and_return(parent)
      expect(presenter.parent_scene_title).to eq("The Fall of Vex")
    end
  end

  describe "#parent_scene_path" do
    it "builds the parent scene's show path from the injected game and url_helpers" do
      parent = build_stubbed(:scene, id: 9)
      allow(scene).to receive(:parent_scene).and_return(parent)
      allow(urls).to receive(:game_scene_path).with(game, parent).and_return("/games/1/scenes/9")

      expect(presenter.parent_scene_path).to eq("/games/1/scenes/9")
    end
  end

  describe "#toggle_notification_preference_path" do
    it "builds the toggle-notification path from the injected game and url_helpers" do
      allow(urls).to receive(:toggle_notification_preference_game_scene_path)
        .with(game, scene).and_return("/games/1/scenes/2/toggle_notification_preference")

      expect(presenter.toggle_notification_preference_path)
        .to eq("/games/1/scenes/2/toggle_notification_preference")
    end
  end

  describe "#quick_child_scene_path" do
    it "builds the new-scene path flagged quick with this scene as parent" do
      allow(urls).to receive(:new_game_scene_path)
        .with(game, quick: true, parent_scene_id: scene.id).and_return("/games/1/scenes/new?quick=true")

      expect(presenter.quick_child_scene_path).to eq("/games/1/scenes/new?quick=true")
    end
  end

  describe "#new_child_scene_path" do
    it "builds the new-scene path with this scene as parent" do
      allow(urls).to receive(:new_game_scene_path)
        .with(game, parent_scene_id: scene.id).and_return("/games/1/scenes/new")

      expect(presenter.new_child_scene_path).to eq("/games/1/scenes/new")
    end
  end

  describe "#edit_participants_path" do
    it "builds the edit-participants path from the injected game and url_helpers" do
      allow(urls).to receive(:edit_game_scene_participants_path)
        .with(game, scene).and_return("/games/1/scenes/2/participants/edit")

      expect(presenter.edit_participants_path).to eq("/games/1/scenes/2/participants/edit")
    end
  end

  describe "#participants_path" do
    it "builds the participants resource path from the injected game and url_helpers" do
      allow(urls).to receive(:game_scene_participants_path)
        .with(game, scene).and_return("/games/1/scenes/2/participants")

      expect(presenter.participants_path).to eq("/games/1/scenes/2/participants")
    end
  end

  describe "#show_path" do
    it "builds the scene's own show path from the injected game and url_helpers" do
      allow(urls).to receive(:game_scene_path).with(game, scene).and_return("/games/1/scenes/2")

      expect(presenter.show_path).to eq("/games/1/scenes/2")
    end
  end
end
