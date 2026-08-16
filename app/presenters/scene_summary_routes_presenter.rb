# typed: strict

# The URLs a scene summary's screens/feed link to, split out of
# SceneSummaryPresenter to keep that class under the project's method
# ceiling. Wraps the SceneSummary model directly (not SceneSummaryPresenter)
# and takes the constructing controller as `urls:` plus the owning `game:`,
# mirroring GameRoutesPresenter.
class SceneSummaryRoutesPresenter < BasePresenter
  extend T::Sig

  sig { params(model: SceneSummary, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The scene this summary belongs to, resolved to a URL.
  sig { returns(String) }
  def scene_path
    urls.game_scene_path(game, @model.scene)
  end

  sig { returns(String) }
  def edit_path
    urls.edit_game_scene_scene_summary_path(game, @model.scene)
  end

  # The summary's own resource path — used both to submit the create/update
  # form and to issue the delete request, since both share one route.
  sig { returns(String) }
  def submit_path
    urls.game_scene_scene_summary_path(game, @model.scene)
  end

  # The scene's absolute URL — RSS items link out from a feed with no
  # request context of their own, so this is the one caller needing `_url`
  # rather than `scene_path`'s in-app relative form. Same game/urls
  # collaborators, different route helper.
  sig { returns(String) }
  def scene_url
    urls.game_scene_url(game, @model.scene)
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
