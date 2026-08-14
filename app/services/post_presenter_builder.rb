# typed: strict
# frozen_string_literal: true

# Builds the PostPresenter/composer-component PostsController's #edit and
# #create need. Only the controller has Pundit's `policy(...)` to hand over
# already resolved (presenters never construct authorization), so this takes
# the game/scene/url_helpers rather than looking them up.
class PostPresenterBuilder
  extend T::Sig

  sig { params(game: T.nilable(Game), scene: T.nilable(Scene), urls: T.untyped).void }
  def initialize(game, scene, urls)
    @game = game
    @scene = scene
    @urls = urls
  end

  sig { params(post: Post, policy: PostPolicy, scene_participants: T::Array[SceneParticipant]).returns(PostPresenter) }
  def post_presenter(post, policy, scene_participants: [])
    PostPresenter.new(
      post, scene_participants: scene_participants, game: @game, scene: @scene, urls: @urls, policy: policy
    )
  end

  sig do
    params(
      post: Post, policy: PostPolicy, game_presenter: GamePresenter, scene_presenter: ScenePresenter
    ).returns(Shared::PostComposerComponent)
  end
  def composer_component(post, policy, game_presenter, scene_presenter)
    Shared::PostComposerComponent.new(post: post_presenter(post, policy), game: game_presenter, scene: scene_presenter)
  end
end
