require "rails_helper"

RSpec.describe SceneTreeBuilder, :db do
  let(:game) { create(:game) }

  def node_titles(presenter)
    presenter.trees.map { |node| node.scene_presenter.title }
  end

  describe "#call" do
    it "returns a SceneTreePresenter" do
      expect(described_class.new([]).call).to be_a(SceneTreePresenter)
    end

    it "treats a parentless scene as a root" do
      scene = create(:scene, game: game, title: "Opening")

      expect(node_titles(described_class.new([ scene ]).call)).to eq([ "Opening" ])
    end

    it "nests a child under its parent rather than rooting it" do
      parent = create(:scene, game: game, title: "Parent")
      child = create(:scene, game: game, title: "Child", parent_scene: parent)

      tree = described_class.new([ parent, child ]).call
      root = T.must(tree.trees.first)

      expect(node_titles(tree)).to eq([ "Parent" ])
      expect(root.children.map { |node| node.scene_presenter.title }).to eq([ "Child" ])
    end

    # A private parent the viewer cannot see is absent from the list; its child
    # still has to render, so it is promoted to a root instead of vanishing.
    it "roots a scene whose parent is missing from the visible set" do
      parent = create(:scene, game: game, title: "Hidden Parent")
      child = create(:scene, game: game, title: "Orphan", parent_scene: parent)

      expect(node_titles(described_class.new([ child ]).call)).to eq([ "Orphan" ])
    end

    it "orders siblings oldest first" do
      parent = create(:scene, game: game, title: "Parent")
      create(:scene, game: game, title: "Later", parent_scene: parent, created_at: 1.hour.ago)
      create(:scene, game: game, title: "Earlier", parent_scene: parent, created_at: 3.hours.ago)

      tree = described_class.new(game.scenes.to_a).call
      root = T.must(tree.trees.first)

      expect(root.children.map { |node| node.scene_presenter.title }).to eq([ "Earlier", "Later" ])
    end

    it "nests grandchildren beneath their own parent" do
      parent = create(:scene, game: game, title: "Parent")
      child = create(:scene, game: game, title: "Child", parent_scene: parent)
      create(:scene, game: game, title: "Grandchild", parent_scene: child)

      tree = described_class.new(game.scenes.to_a).call
      child_node = T.must(T.must(tree.trees.first).children.first)

      expect(child_node.children.map { |node| node.scene_presenter.title }).to eq([ "Grandchild" ])
    end
  end

  describe ".for" do
    it "loads only the scenes the viewer may see" do
      viewer = create(:user, :with_profile)
      create(:game_member, game: game, user: viewer, role: "player", status: "active")
      create(:scene, game: game, title: "Visible")
      create(:scene, :private, game: game, title: "Secret")

      expect(node_titles(described_class.for(viewer, game).call)).to eq([ "Visible" ])
    end

    it "orders the loaded scenes oldest first" do
      viewer = create(:user, :with_profile)
      create(:game_member, game: game, user: viewer, role: "player", status: "active")
      create(:scene, game: game, title: "Later", created_at: 1.hour.ago)
      create(:scene, game: game, title: "Earlier", created_at: 3.hours.ago)

      expect(node_titles(described_class.for(viewer, game).call)).to eq([ "Earlier", "Later" ])
    end
  end
end
