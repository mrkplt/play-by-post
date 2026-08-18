# typed: strict

class PostsController < ApplicationController
  extend T::Sig
  include PostScoped

  before_action :require_participant!
  before_action :require_active_member_for_write!, only: %i[create]
  before_action :require_editable!, only: %i[edit update]
  after_action :verify_authorized

  sig { void }
  def mark_read
    authorize post, :mark_read?
    PostRead.mark!(post, current_user)
    head :no_content
  end

  sig { void }
  def edit
    authorize post
    assign_game_and_scene_presenters
    @scene_navigation_presenter = T.let(
      SceneNavigationPresenter.new(T.must(@scene_presenter), game: game, urls: self),
      T.nilable(SceneNavigationPresenter)
    )
    @post_presenter = T.let(
      presenter_builder.post_presenter(PostPresenterBuilder::AuthorizedPost.new(post: post, policy: policy(post))),
      T.nilable(PostPresenter)
    )
  end

  sig { void }
  def create
    new_post = build_new_post
    authorize new_post, :create?
    authorized_post = PostPresenterBuilder::AuthorizedPost.new(post: new_post, policy: policy(new_post))

    new_post.save ? render_created(authorized_post) : render_composer_errors(authorized_post)
  end

  sig { void }
  def update
    authorize post
    post.update!(content: params[:post][:content], last_edited_at: Time.current) # mutant:disable

    redirect_to game_scene_path(game, scene)
  end

  private

  sig { returns(PostPresenterBuilder) }
  def presenter_builder
    PostPresenterBuilder.new(game, scene, self)
  end

  sig { returns(Post) }
  def build_new_post
    new_post = PostDraft.new(scene, current_user).publish_target(post_params)
    assign_game_and_scene_presenters
    new_post
  end

  sig { params(authorized_post: PostPresenterBuilder::AuthorizedPost).void }
  def render_created(authorized_post)
    @post_presenter = T.let(
      presenter_builder.post_presenter_with_participants(authorized_post), T.nilable(PostPresenter)
    )

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to game_scene_path(game, scene) }
    end
  end

  sig { params(authorized_post: PostPresenterBuilder::AuthorizedPost).void }
  def render_composer_errors(authorized_post)
    respond_with_composer_errors(presenter_builder.composer_component(authorized_post, page_context))
  end

  sig { params(component: Shared::PostComposerComponent).void }
  def respond_with_composer_errors(component)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("post_composer", component) }
      format.html { redirect_to game_scene_path(game, scene), alert: "Could not create post." }
    end
  end

  sig { returns(PostPresenterBuilder::PageContext) }
  def page_context
    PostPresenterBuilder::PageContext.new(
      game_presenter: T.must(@game_presenter), scene_presenter: T.must(@scene_presenter)
    )
  end

  sig { void }
  def assign_game_and_scene_presenters
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
    @scene_presenter = T.let(ScenePresenter.new(scene, game: game, urls: self), T.nilable(ScenePresenter))
  end

  sig { void }
  def require_participant!
    return if policy(scene.posts.new).participate?

    redirect_to game_scene_path(game, scene), alert: "You are not a participant in this scene."
  end

  sig { void }
  def require_editable!
    redirect_to game_scene_path(game, scene), alert: "This post can no longer be edited." unless policy(post).update?
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(game)
  end

  sig { returns(ActionController::Parameters) }
  def post_params
    params.require(:post).permit(:content, :is_ooc)
  end
end
