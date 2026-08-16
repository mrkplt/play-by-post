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

  # A post paired with the policy PostsController already resolved for it —
  # the combination every presenter/component this builder produces needs,
  # bundled so callers pass one argument instead of the same pair repeatedly.
  class AuthorizedPost < T::Struct
    const :post, Post
    const :policy, PostPolicy
  end

  sig { params(authorized_post: AuthorizedPost, scene_participants: T::Array[SceneParticipant]).returns(PostPresenter) }
  def post_presenter(authorized_post, scene_participants: [])
    PostPresenter.new(
      authorized_post.post, scene_participants: scene_participants, game: @game, scene: @scene, urls: @urls,
      policy: authorized_post.policy
    )
  end

  # #post_presenter with this scene's participants already loaded — the
  # combination PostsController#create needs to present a just-created post,
  # rather than making the controller fetch scene_participants itself.
  sig { params(authorized_post: AuthorizedPost).returns(PostPresenter) }
  def post_presenter_with_participants(authorized_post)
    post_presenter(authorized_post, scene_participants: scene_participants)
  end

  # The scene's participants, loaded so each post can name its speaker.
  sig { returns(T::Array[SceneParticipant]) }
  def scene_participants
    T.must(@scene).scene_participants.includes(:character, :user).to_a
  end

  # The game/scene presenter pair a page has already built for its own
  # chrome — bundled so #composer_component takes one argument for "where
  # this composer lives" instead of two.
  class PageContext < T::Struct
    extend T::Sig

    const :game_presenter, GamePresenter
    const :scene_presenter, ScenePresenter

    sig { params(post_presenter: PostPresenter).returns(Shared::PostComposerComponent) }
    def composer_for(post_presenter)
      Shared::PostComposerComponent.new(post: post_presenter, game: game_presenter, scene: scene_presenter)
    end
  end

  sig { params(authorized_post: AuthorizedPost, page: PageContext).returns(Shared::PostComposerComponent) }
  def composer_component(authorized_post, page)
    page.composer_for(post_presenter(authorized_post))
  end
end
