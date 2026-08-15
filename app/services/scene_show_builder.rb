# typed: strict
# frozen_string_literal: true

# Builds the presenter set ScenesController#show renders: the scene itself, its
# navigation, its posts and the summary. Only the controller has Pundit's
# `policy(...)`, so it hands each resolved policy over rather than letting a
# presenter construct authorization (R2).
class SceneShowBuilder
  extend T::Sig

  # Everything about the current request the presenters need: who is looking,
  # the url helpers to build links with, and Pundit's `policy` as a callable so
  # a policy can be resolved per post without reaching for authorization here.
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

  # nil when the scene has no summary yet — the view's own condition (scene
  # resolved? && summary present?) reads the presenter directly rather than
  # having this build the policy speculatively.
  sig { returns(T.nilable(SceneSummaryPresenter)) }
  def summary_presenter
    summary = @scene.scene_summary
    return nil unless summary

    viewer = @context.current_user
    SceneSummaryPresenter.new(
      summary, game: @game, urls: @context.urls, policy: SceneSummaryPolicy.new(viewer, summary)
    )
  end

  private

  # Published posts wrapped for display, each with its own Pundit-resolved
  # policy (R2: presenters never construct authorization).
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
