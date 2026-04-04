# typed: true

class PostsController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :set_scene
  before_action :require_participant!
  before_action :require_active_member_for_write!, only: %i[create save_draft]
  before_action :set_post, only: %i[edit update mark_read]

  sig { void }
  def mark_read
    PostRead.mark!(@post, current_user)
    head :no_content
  end

  sig { void }
  def edit
    unless @post.editable_by?(current_user)
      redirect_to game_scene_path(@game, @scene), alert: "This post can no longer be edited."
    end
  end

  sig { void }
  def discard_draft
    draft = @scene.posts.drafts.find_by(user: current_user)
    draft&.destroy
    redirect_to game_scene_path(@game, @scene), notice: "Draft discarded."
  end

  sig { void }
  def save_draft
    draft = @scene.posts.drafts.find_or_initialize_by(user: current_user)
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
    draft = @scene.posts.drafts.find_by(user: current_user)

    if draft
      draft.assign_attributes(post_params.merge(draft: false, last_edited_at: nil))
      @post = draft
    else
      @post = @scene.posts.new(post_params)
      @post.user = current_user
    end

    if @post.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to game_scene_path(@game, @scene) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post_composer", Shared::PostComposerComponent.new(post: @post, game: @game, scene: @scene)) }
        format.html { redirect_to game_scene_path(@game, @scene), alert: "Could not create post." }
      end
    end
  end

  sig { void }
  def update
    unless @post.editable_by?(current_user)
      redirect_to game_scene_path(@game, @scene), alert: "This post can no longer be edited."
      return
    end

    @post.update!(content: params[:post][:content], last_edited_at: Time.current)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to game_scene_path(@game, @scene) }
    end
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def set_scene
    @scene = @game.scenes.find(params[:scene_id])
  end

  sig { void }
  def set_post
    @post = @scene.posts.find(params[:id])
  end

  sig { void }
  def require_participant!
    unless @scene.participant?(current_user) || @game.game_master?(current_user)
      redirect_to game_scene_path(@game, @scene), alert: "You are not a participant in this scene."
    end
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(@game)
  end

  sig { returns(ActionController::Parameters) }
  def post_params
    params.require(:post).permit(:content, :is_ooc, :image)
  end
end
