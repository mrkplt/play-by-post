# typed: strict

# The "End Scene" / composer draft endpoints for a scene, split out of
# ScenePresenter to keep that class under the project's method ceiling: route
# resolution is a distinct concern from the scene's own display values. Wraps
# the Scene model directly (not ScenePresenter) and takes the constructing
# controller as `urls:` plus the owning `game:`, mirroring GameRoutesPresenter.
class SceneRoutesPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Scene, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The "End Scene" form's submit target.
  sig { returns(String) }
  def resolve_path
    urls.resolve_game_scene_path(game, @model)
  end

  # The composer's autosave endpoint.
  sig { returns(String) }
  def save_draft_url
    urls.save_draft_game_scene_posts_path(game, @model) # mutant:disable
  end

  # The composer's discard-draft endpoint.
  sig { returns(String) }
  def discard_draft_url
    urls.discard_draft_game_scene_posts_path(game, @model) # mutant:disable
  end

  private

  sig { returns(T.untyped) }
  def urls
    @options.fetch(:urls)
  end

  sig { returns(Game) }
  def game
    @options.fetch(:game)
  end
end
