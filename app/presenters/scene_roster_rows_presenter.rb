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

  # One row per participant with a character: the character name, this scene's
  # title, and the character's portrait URL (nil → monogram fallback). The
  # roster preview is in-game, so the identity is the character, not the player.
  sig { returns(T::Array[T::Hash[Symbol, T.nilable(String)]]) }
  def rows
    @model.model.scene_participants.filter_map do |participant|
      character = participant.character
      next unless character

      { name: character.name, scene: @model.title, avatar_url: portrait_url(character) }
    end
  end

  private

  sig { params(character: Character).returns(T.nilable(String)) }
  def portrait_url(character)
    variant = character.portrait_variant
    variant && @options.fetch(:helpers).url_for(variant)
  end
end
