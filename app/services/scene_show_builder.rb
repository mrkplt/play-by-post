# typed: strict
# frozen_string_literal: true

# The controller hands each resolved policy over rather than letting a
# presenter construct authorization (R2).
class SceneShowBuilder
  extend T::Sig

  # Pundit's `policy` travels as a callable so a policy can be resolved per
  # post without reaching for authorization here.
  class Context < T::Struct
    const :urls, T.untyped
    const :current_user, User
    const :policies, T.untyped
  end

  sig { params(scene: Scene, game: Game, context: Context).void }
  def initialize(scene, game:, context:)
    @scene = scene
    @game = game
    @context = context
  end

  sig { params(game_presenter: GamePresenter).returns(SceneScreenPresenter) }
  def screen(game_presenter)
    summary = summary_presenter

    SceneScreenPresenter.new(
      scene_presenter,
      game_presenter: game_presenter,
      navigation: navigation_presenter,
      show: show_presenter,
      posts: posts_presenter,
      summary: summary,
      summary_pending: summary_pending?(summary),
      summary_pending_frame: SceneSummaryChannel::PENDING_FRAME_ID,
      summary_stream: summary_stream,
      summary_stream_data: { scene_id: @scene.id }
    )
  end

  sig { returns(ScenePresenter) }
  def scene_presenter
    @scene_presenter ||= T.let(
      ScenePresenter.new(@scene, game: @game, urls: @context.urls),
      T.nilable(ScenePresenter)
    )
  end

  sig { returns(SceneNavigationPresenter) }
  def navigation_presenter
    SceneNavigationPresenter.new(scene_presenter, game: @game, urls: @context.urls)
  end

  sig { returns(SceneShowPresenter) }
  def show_presenter
    SceneShowPresenter.new(
      scene_presenter, game: @game, urls: @context.urls, current_user: @context.current_user
    )
  end

  sig { returns(ScenePostsPresenter) }
  def posts_presenter
    viewer = @context.current_user

    ScenePostsPresenter.new(
      scene_presenter, game: @game, urls: @context.urls, current_user: viewer,
      post_policy: PostPolicy.new(viewer, @scene.posts.new),
      post_presenters: post_presenters
    )
  end

  # nil until the scene has a summary — building the policy speculatively
  # would authorize a record that does not exist yet. A draft summary is visible
  # only to a GM (its author); a player sees nothing until it is published, so
  # the has_one (which no published scope can reach) is gated here.
  sig { returns(T.nilable(SceneSummaryPresenter)) }
  def summary_presenter
    summary = @scene.scene_summary
    return nil unless summary && summary_visible?(summary)

    SceneSummaryPresenter.new(
      summary, game: @game, urls: @context.urls, policy: summary_policy(summary), viewer: @context.current_user
    )
  end

  private

  # The async summary is "pending" for this viewer when the scene is resolved
  # and the game has AI summaries on, but no summary is visible to them yet —
  # the moment the pending frame (Fizzy #115) should show a spinner. A draft (or
  # an AI-hidden summary) counts as not-yet-visible, so the frame keeps waiting
  # for a broadcast in this viewer's visibility class.
  sig { params(summary: T.nilable(SceneSummaryPresenter)).returns(T::Boolean) }
  def summary_pending?(summary)
    !summary && @scene.resolved? && @game.ai_summaries_enabled? ? true : false
  end

  # The signed Turbo Stream this viewer subscribes to while the summary is
  # pending: their own visibility class, so a completion broadcast reaches them
  # only if the finished summary is visible to their class. Built from the same
  # SceneSummaryVisibility mapping the worker broadcasts through.
  sig { returns(T::Array[T.untyped]) }
  def summary_stream
    # The GM answer comes from the game directly (the same question
    # SceneSummaryPolicy#manage? asks) so no throwaway SceneSummary is built —
    # building one would back-populate @scene.scene_summary and make the page
    # think a summary already exists.
    klass = SceneSummaryVisibility.for_viewer(game: @game, viewer: @context.current_user)
    [ @scene, :summary, klass ]
  end

  # The per-viewer visibility rule lives on SceneSummary so the scene page and
  # the broadcast agree on who may see a summary.
  sig { params(summary: SceneSummary).returns(T::Boolean) }
  def summary_visible?(summary)
    summary.visible_to?(@context.current_user)
  end

  sig { params(summary: SceneSummary).returns(SceneSummaryPolicy) }
  def summary_policy(summary)
    SceneSummaryPolicy.new(@context.current_user, summary)
  end

  sig { returns(T::Array[PostPresenter]) }
  def post_presenters
    participants = @scene.scene_participants.includes(:character, :user).to_a

    published_posts.map do |post|
      PostPresenter.new(
        post, scene_participants: participants, game: @game, scene: @scene,
        urls: @context.urls, policy: @context.policies.call(post)
      )
    end
  end

  sig { returns(T::Array[Post]) }
  def published_posts
    @scene.posts.published.includes(:user).order(:created_at).to_a
  end
end
