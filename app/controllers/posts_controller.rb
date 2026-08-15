# typed: strict

class PostsController < ApplicationController
  extend T::Sig
  include ImageAttachable
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
    @post_presenter = T.let(presenter_builder.post_presenter(post, policy(post)), T.nilable(PostPresenter))
  end

  sig { void }
  def create
    new_post = post_draft.publish_target(post_params)
    post_policy = policy(new_post)
    authorize new_post, :create?
    attach_uploaded_image(new_post, game, param_key: :post)
    assign_game_and_scene_presenters

    new_post.save ? render_created(new_post, post_policy) : render_composer_errors(new_post, post_policy)
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

  sig { returns(PostDraft) }
  def post_draft
    PostDraft.new(scene, current_user)
  end

  # The new post appended to the thread; the turbo_stream template renders
  # @post_presenter.
  sig { params(new_post: Post, post_policy: PostPolicy).void }
  def render_created(new_post, post_policy)
    builder = presenter_builder
    built = builder.post_presenter(new_post, post_policy, scene_participants: builder.scene_participants)
    @post_presenter = T.let(built, T.nilable(PostPresenter))

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to game_scene_path(game, scene) }
    end
  end

  # A failed save re-renders the composer in place, holding what was typed.
  sig { params(new_post: Post, post_policy: PostPolicy).void }
  def render_composer_errors(new_post, post_policy)
    component = presenter_builder.composer_component(new_post, post_policy, page_context)

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
