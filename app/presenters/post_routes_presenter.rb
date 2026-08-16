# typed: strict

# The "mark read" / edit endpoints for a post, split out of PostPresenter to
# keep that class under the project's method ceiling: route resolution is a
# distinct concern from the post's own display values. Wraps the Post model
# directly (not PostPresenter) and takes the constructing controller as
# `urls:` plus the owning `game:`/`scene:`, mirroring GameRoutesPresenter.
class PostRoutesPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Post, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def mark_read_url
    urls.mark_read_game_scene_post_path(game, scene, @model) # mutant:disable
  end

  sig { returns(String) }
  def edit_url
    urls.edit_game_scene_post_path(game, scene, @model) # mutant:disable
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

  sig { returns(Scene) }
  def scene
    @options.fetch(:scene, @model.scene)
  end
end
