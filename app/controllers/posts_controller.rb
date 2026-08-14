# typed: strict

class PostsController < ApplicationController
  extend T::Sig

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
  end

  sig { void }
  def discard_draft
    draft = T.must(@scene).posts.drafts.find_by(user: current_user)
    draft&.destroy
    redirect_to game_scene_path(@game, @scene), notice: "Draft discarded."
  end

  sig { void }
  def save_draft
    draft = T.must(@scene).posts.drafts.find_or_initialize_by(user: current_user)
    draft.assign_attributes(
      content: params.dig(:post, :content),
      is_ooc: params.dig(:post, :is_ooc) || false,
      draft: true
    )

    if draft.save
      render json: { id: draft.id }, status: :ok
    else
      render json: { errors: draft.errors.full_messages }, status: :unprocessable_content
    end
  end

  sig { void }
  def create
    existing_draft = T.must(@scene).posts.drafts.find_by(user: current_user)

    post = if existing_draft
      existing_draft.assign_attributes(post_params.merge(draft: false, last_edited_at: nil))
      existing_draft
    else
      T.must(@scene).posts.new(post_params).tap { |p| p.user = current_user }
    end

    authorize post, :create?
    attach_image(post)

    if post.save
      @post_presenter = T.let(
        PostPresenter.new(post, scene_participants: T.must(@scene).scene_participants.includes(:character, :user).to_a),
        T.nilable(PostPresenter)
      )
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to game_scene_path(@game, @scene) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post_composer", Shared::PostComposerComponent.new(post: post, game: T.must(@game), scene: T.must(@scene))) }
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

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_scene
    @scene = T.let(T.must(@game).scenes.find(params[:scene_id]), T.nilable(Scene))
  end

  sig { void }
  def set_post
    @post = T.let(T.must(@scene).posts.find(params[:id]), T.nilable(Post))
  end

  sig { void }
  def require_participant!
    unless policy(T.must(@scene).posts.new).participate?
      redirect_to game_scene_path(@game, @scene), alert: "You are not a participant in this scene."
    end
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

  sig { params(post: Post).void }
  def attach_image(post)
    image = params.dig(:post, :image)
    return unless image.respond_to?(:original_filename)

    AttachmentUploader.attach(
      attachment: post.image,
      attachable: image,
      kind: "post_image",
      user: current_user,
      game: @game,
      original_filename: image.original_filename
    )
  end
end
