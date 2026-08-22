# typed: strict

# Bundles the scene screen's presenters so the controller assigns one ivar
# instead of six. Wraps ScenePresenter as its subject; the siblings are options.
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

  # True when the async SceneSummaryJob is (from this viewer's vantage) still
  # working: the pending frame renders in place of a summary. Mutually exclusive
  # with summary? — one or the other, never both.
  sig { returns(T::Boolean) }
  def summary_pending?
    @options.fetch(:summary_pending)
  end

  # The Turbo Frame id the pending frame carries and the completion broadcast
  # targets.
  sig { returns(String) }
  def summary_pending_frame
    @options.fetch(:summary_pending_frame)
  end

  # The signed Turbo Stream the pending frame subscribes to — this viewer's
  # visibility class, as `[scene, :summary, class]`.
  sig { returns(T::Array[T.untyped]) }
  def summary_stream
    @options.fetch(:summary_stream)
  end

  # Extra subscription params the authorizing channel needs (the scene id).
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def summary_stream_data
    @options.fetch(:summary_stream_data)
  end

  # The GM action row shows only while the scene is still open.
  sig { returns(T::Boolean) }
  def gm_actions?
    game.can_manage? && !scene.resolved?
  end
end
