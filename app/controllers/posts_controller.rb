# typed: strict

class PostsController < ApplicationController
  extend T::Sig
  include ImageAttachable
  include PostScoped

  before_action :require_participant!
  before_action :require_active_member_for_write!, only: %i[create save_draft]
  before_action :require_editable!, only: %i[edit update]
  after_action :verify_authorized, except: %i[discard_draft save_draft]

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
  def discard_draft
    scene.posts.drafts.find_by(user: current_user)&.destroy
    redirect_to game_scene_path(game, scene), notice: "Draft discarded."
  end

  sig { void }
  def save_draft
    draft = scene.posts.drafts.find_or_initialize_by(user: current_user)
    draft.assign_attributes(content: params.dig(:post, :content), is_ooc: params.dig(:post, :is_ooc) || false, draft: true)

    if draft.save
      render json: { id: draft.id }, status: :ok
    else
      render json: { errors: draft.errors.full_messages }, status: :unprocessable_content
    end
  end

  sig { void }
  def create
    new_post = draft_or_new_post
    post_policy = policy(new_post)
    authorize new_post, :create?
    attach_uploaded_image(new_post, game, param_key: :post)
    assign_game_and_scene_presenters

    if new_post.save
      participants = scene.scene_participants.includes(:character, :user).to_a
      built = presenter_builder.post_presenter(new_post, post_policy, scene_participants: participants)
      @post_presenter = T.let(built, T.nilable(PostPresenter))
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to game_scene_path(game, scene) }
      end
    else
      page = PostPresenterBuilder::PageContext.new(
        game_presenter: T.must(@game_presenter), scene_presenter: T.must(@scene_presenter)
      )
      component = presenter_builder.composer_component(new_post, post_policy, page)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post_composer", component) }
        format.html { redirect_to game_scene_path(game, scene), alert: "Could not create post." }
      end
    end
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
  def draft_or_new_post
    existing_draft = scene.posts.drafts.find_by(user: current_user)
    return update_draft_attributes(existing_draft) if existing_draft

    new_post_from_params
  end

  sig { params(draft: Post).returns(Post) }
  def update_draft_attributes(draft)
    draft.tap { |draft_post| draft_post.assign_attributes(post_params.merge(draft: false, last_edited_at: nil)) }
  end

  sig { returns(Post) }
  def new_post_from_params
    scene.posts.new(post_params).tap { |new_post| new_post.user = current_user }
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
