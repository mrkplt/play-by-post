# @label Scene Card
class Shared::SceneCardComponentPreview < ViewComponent::Preview
  def active_scene
    scene = Scene.new(title: "The Tavern", updated_at: 2.days.ago, private: false)
    game = Game.new(name: "Sample Game")
    presenter = ScenePresenter.new(scene)
    render(Shared::SceneCardComponent.new(scene: presenter, game: game))
  end

  def resolved_scene
    scene = Scene.new(title: "The Forest Path", updated_at: 7.days.ago, private: false, resolved_at: 3.days.ago)
    game = Game.new(name: "Sample Game")
    presenter = ScenePresenter.new(scene)
    render(Shared::SceneCardComponent.new(scene: presenter, game: game))
  end

  def private_scene
    scene = Scene.new(title: "Secret Meeting", updated_at: 1.day.ago, private: true)
    game = Game.new(name: "Sample Game")
    presenter = ScenePresenter.new(scene)
    render(Shared::SceneCardComponent.new(scene: presenter, game: game))
  end
end
