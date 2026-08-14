# typed: strict

class PostsController < ApplicationController
  extend T::Sig
  include ImageAttachable
  include PostScoped

  before_action :set_game
  before_action :set_scene
  before_action :require_participant!
  before_action :require_active_member_for_write!, only: %i[create save_draft]
  before_action :set_post, only: %i[edit update mark_read]
  before_action :require_editable!, only: %i[edit update]
  after_action :verify_authorized, except: %i[discard_draft save_draft]

  sig { void }
  def mark_read
    authorize @post, :mark_read?
    PostRead.mark!(T.must(@post), current_user)
    head :no_content
  end

  sig { void }
  def edit
    authorize @post
    assign_game_and_scene_presenters
    @post_presenter = T.let(presenter_builder.post_presenter(T.must(@post), policy(@post)), T.nilable(PostPresenter))
  end

  sig { void }
  def discard_draft
    T.must(@scene).posts.drafts.find_by(user: current_user)&.destroy
    redirect_to game_scene_path(@game, @scene), notice: "Draft discarded."
  end

  sig { void }
  def save_draft
    draft = T.must(@scene).posts.drafts.find_or_initialize_by(user: current_user)
    draft.assign_attributes(content: params.dig(:post, :content), is_ooc: params.dig(:post, :is_ooc) || false, draft: true)

    if draft.save
      render json: { id: draft.id }, status: :ok
    else
      render json: { errors: draft.errors.full_messages }, status: :unprocessable_content
    end
  end

  sig { void }
  def create
    post = draft_or_new_post
    post_policy = policy(post)
    authorize post, :create?
    attach_uploaded_image(post, @game, param_key: :post)
    assign_game_and_scene_presenters

    if post.save
      participants = T.must(@scene).scene_participants.includes(:character, :user).to_a
      built = presenter_builder.post_presenter(post, post_policy, scene_participants: participants)
      @post_presenter = T.let(built, T.nilable(PostPresenter))
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to game_scene_path(@game, @scene) }
      end
    else
      page = PostPresenterBuilder::PageContext.new(
        game_presenter: T.must(@game_presenter), scene_presenter: T.must(@scene_presenter)
      )
      component = presenter_builder.composer_component(post, post_policy, page)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post_composer", component) }
        format.html { redirect_to game_scene_path(@game, @scene), alert: "Could not create post." }
      end
    end
  end

  sig { void }
  def update
    authorize @post
    T.must(@post).update!(content: params[:post][:content], last_edited_at: Time.current) # mutant:disable

    redirect_to game_scene_path(@game, @scene)
  end

  private

  sig { returns(PostPresenterBuilder) }
  def presenter_builder
    PostPresenterBuilder.new(@game, @scene, self)
  end

  sig { returns(Post) }
  def draft_or_new_post
    existing_draft = T.must(@scene).posts.drafts.find_by(user: current_user)
    return update_draft_attributes(existing_draft) if existing_draft

    new_post_from_params
  end

  sig { params(draft: Post).returns(Post) }
  def update_draft_attributes(draft)
    draft.tap { |post| post.assign_attributes(post_params.merge(draft: false, last_edited_at: nil)) }
  end

  sig { returns(Post) }
  def new_post_from_params
    T.must(@scene).posts.new(post_params).tap { |post| post.user = current_user }
  end

  sig { void }
  def assign_game_and_scene_presenters
    @game_presenter = T.let(GamePresenter.new(T.must(@game), policy: policy(@game)), T.nilable(GamePresenter))
    @scene_presenter = T.let(ScenePresenter.new(T.must(@scene), game: @game, urls: self), T.nilable(ScenePresenter))
  end

  sig { void }
  def require_participant!
    return if policy(T.must(@scene).posts.new).participate?

    redirect_to game_scene_path(@game, @scene), alert: "You are not a participant in this scene."
  end

  sig { void }
  def require_editable!
    redirect_to game_scene_path(@game, @scene), alert: "This post can no longer be edited." unless policy(@post).update?
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(T.must(@game))
  end

  sig { returns(ActionController::Parameters) }
  def post_params
    params.require(:post).permit(:content, :is_ooc)
  end
end
