# typed: strict

# The whole scene screen (ScenesController#show) as one object: the game and
# scene chrome, navigation, the viewer-scoped show state, the post list and the
# summary. Each part is still its own presenter — this only bundles them, so
# the controller assigns one ivar instead of six and the template reaches each
# part by name. Wraps ScenePresenter as its subject (composition, per the
# layering rule that a presenter's subject may be another presenter); the
# sibling presenters come in as options.
class SceneScreenPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(ScenePresenter) }
  def scene
    @model
  end

  sig { returns(GamePresenter) }
  def game
    @options.fetch(:game_presenter)
  end

  sig { returns(SceneNavigationPresenter) }
  def navigation
    @options.fetch(:navigation)
  end

  sig { returns(SceneShowPresenter) }
  def show
    @options.fetch(:show)
  end

  sig { returns(ScenePostsPresenter) }
  def posts
    @options.fetch(:posts)
  end

  # nil until the scene is resolved and a summary has been generated.
  sig { returns(T.nilable(SceneSummaryPresenter)) }
  def summary
    @options[:summary]
  end

  # The summary block renders only on a resolved scene that has one.
  sig { returns(T::Boolean) }
  def summary?
    scene.resolved? && summary ? true : false
  end

  # The GM action row shows only while the scene is still open.
  sig { returns(T::Boolean) }
  def gm_actions?
    game.can_manage? && !scene.resolved?
  end
end
