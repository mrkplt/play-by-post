# typed: strict

# View model for Shared::SceneCardComponent's parent/child link cluster.
# Wraps a ScenePresenter — composition, not duplication — so the card-only
# thread-navigation concerns live apart from ScenePresenter's broader surface.
class SceneCardPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def parent_scene?
    @model.model.parent_scene.present?
  end

  sig { returns(ScenePresenter) }
  def parent_scene_presenter
    ScenePresenter.new(@model.model.parent_scene)
  end

  # This scene's child scenes that belong to the given game, wrapped for
  # display — the scene card's "continued in" links show only same-game
  # children.
  sig { params(game: GamePresenter).returns(T::Array[ScenePresenter]) }
  def child_scenes_in(game)
    @model.model.child_scenes.select { |c| c.game_id == game.id }.map { |c| ScenePresenter.new(c) }
  end
end
