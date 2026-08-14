# @label Tree Node
class Shared::TreeNodeComponentPreview < ViewComponent::Preview
  def single_active_node
    game  = Game.new(id: 1, name: "Sample Game")
    scene = Scene.new(id: 1, title: "The Throne Room", created_at: 3.days.ago, private: false)
    node = Shared::TreeNodeComponent::Node.new(scene_presenter: ScenePresenter.new(scene), children: [])
    render(Shared::TreeNodeComponent.new(node: node, game_presenter: game_presenter(game), depth: 0))
  end

  def single_resolved_node
    game  = Game.new(id: 1, name: "Sample Game")
    scene = Scene.new(id: 2, title: "The Dungeon", created_at: 10.days.ago, private: false, resolved_at: 5.days.ago)
    node = Shared::TreeNodeComponent::Node.new(scene_presenter: ScenePresenter.new(scene), children: [])
    render(Shared::TreeNodeComponent.new(node: node, game_presenter: game_presenter(game), depth: 0))
  end

  def private_node
    game  = Game.new(id: 1, name: "Sample Game")
    scene = Scene.new(id: 3, title: "Secret Chamber", created_at: 1.day.ago, private: true)
    node = Shared::TreeNodeComponent::Node.new(scene_presenter: ScenePresenter.new(scene), children: [])
    render(Shared::TreeNodeComponent.new(node: node, game_presenter: game_presenter(game), depth: 0))
  end

  def with_children
    game   = Game.new(id: 1, name: "Sample Game")
    parent = Scene.new(id: 4, title: "The Forest", created_at: 7.days.ago, private: false)
    child  = Scene.new(id: 5, title: "The Clearing", created_at: 3.days.ago, private: false)
    node = Shared::TreeNodeComponent::Node.new(
      scene_presenter: ScenePresenter.new(parent),
      children: [ Shared::TreeNodeComponent::Node.new(scene_presenter: ScenePresenter.new(child), children: []) ]
    )
    render(Shared::TreeNodeComponent.new(node: node, game_presenter: game_presenter(game), depth: 0))
  end

  private

  def game_presenter(game)
    GamePresenter.new(game, policy: GamePolicy.new(User.new, game))
  end
end
