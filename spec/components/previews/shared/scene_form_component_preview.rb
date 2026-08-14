# @label Scene Form
class Shared::SceneFormComponentPreview < ViewComponent::Preview
  def full_new_scene
    game = Game.first || Game.new(name: "Sample Game")
    render(Shared::SceneFormComponent.new(
      game: GamePresenter.new(game, policy: nil),
      scene: ScenePresenter.new(game.scenes.new),
      players_with_characters: [],
      parent_options: [ [ "The Tavern", 1 ], [ "The Road (Resolved)", 2 ] ],
      quick: false,
      selected_character_ids: [],
      selected_parent_scene_id: nil,
      back_href: "#"
    ))
  end

  def quick_scene
    game = Game.first || Game.new(name: "Sample Game")
    render(Shared::SceneFormComponent.new(
      game: GamePresenter.new(game, policy: nil),
      scene: ScenePresenter.new(game.scenes.new),
      players_with_characters: [],
      parent_options: [],
      quick: true,
      selected_character_ids: [ "1", "2" ],
      selected_parent_scene_id: "7",
      back_href: "#"
    ))
  end
end
