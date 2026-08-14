# typed: strict

# View model for one scene's contribution to the game roster preview's "In
# Active Scenes" list. Wraps a ScenePresenter — composition, not duplication
# — so this narrow read (per-participant character/scene-title pairs) lives
# apart from ScenePresenter's broader surface, purely to keep each presenter
# under the project's file-length ceiling.
class SceneRosterRowsPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # One row per participant with a character, name paired with this scene's
  # title.
  sig { returns(T::Array[T::Hash[Symbol, String]]) }
  def rows
    @model.model.scene_participants.filter_map do |participant|
      character = participant.character
      next unless character

      { name: character.name, scene: @model.title }
    end
  end
end
