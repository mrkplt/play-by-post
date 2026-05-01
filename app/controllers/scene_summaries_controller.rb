# typed: true

class SceneSummariesController < ApplicationController
  extend T::Sig

  skip_before_action :authenticate_user!, only: [ :index ]

  before_action :set_game
  before_action :require_game_access!, only: %i[new create edit update destroy]
  before_action :set_scene, only: %i[new create edit update destroy]
  before_action :require_resolved_scene!, only: %i[new create]
  before_action :require_gm!, only: %i[new create edit update destroy]
  before_action :set_summary, only: %i[edit update destroy]

  sig { void }
  def index
    respond_to do |format|
      format.html do
        unless user_signed_in? && game_access_granted?
          redirect_to new_user_session_path
          return
        end
        summaries = scene_summaries_for_game
        @pagy, @summaries = pagy(summaries, limit: 20)
        @is_gm = @game.game_master?(current_user)
      end
      format.rss do
        unless rss_access_allowed?(params[:token])
          head :unauthorized
          return
        end
        @summaries = scene_summaries_for_game.limit(20)
        render layout: false
      end
    end
  end

  sig { void }
  def new
    @summary = @scene.build_scene_summary
  end

  sig { void }
  def create
    if @scene.scene_summary.present?
      redirect_to edit_game_scene_scene_summary_path(@game, @scene),
                  alert: "A summary already exists. Edit it instead."
      return
    end

    @summary = @scene.build_scene_summary(summary_params.merge(edited_by: current_user, edited_at: Time.current))
    if @summary.save
      redirect_to game_scene_path(@game, @scene), notice: "Summary saved."
    else
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def edit
  end

  sig { void }
  def update
    attrs = summary_params.merge(edited_by: current_user, edited_at: Time.current,
                                 generated_at: nil, model_used: nil,
                                 input_tokens: nil, output_tokens: nil)
    if @summary.update(attrs)
      redirect_to game_scene_path(@game, @scene), notice: "Summary updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    @summary.destroy!
    redirect_to game_scene_path(@game, @scene), notice: "Summary deleted."
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
  def set_summary
    @summary = @scene.scene_summary
    redirect_to game_scene_path(@game, @scene), alert: "No summary found." unless @summary
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless game_access_granted?
  end

  sig { returns(T::Boolean) }
  def game_access_granted?
    membership = @game.member_for(current_user)
    return true if membership&.game_master?
    return true if membership&.active? || membership&.removed?

    false
  end

  sig { void }
  def require_gm!
    return if @game.game_master?(current_user)

    redirect_to game_path(@game), alert: "Only the GM can manage summaries."
  end

  sig { void }
  def require_resolved_scene!
    return if @scene.resolved?

    redirect_to game_scene_path(@game, @scene), alert: "Summaries are only available for resolved scenes."
  end

  sig { returns(ActiveRecord::Relation) }
  def scene_summaries_for_game
    SceneSummary
      .joins(scene: :game)
      .where(scenes: { game_id: @game.id, private: false })
      .where.not(scenes: { resolved_at: nil })
      .includes(:scene)
      .order("scenes.resolved_at DESC")
  end

  sig { params(token: T.nilable(String)).returns(T::Boolean) }
  def rss_access_allowed?(token)
    if user_signed_in?
      return true if @game.active_members.exists?(user: current_user)
    end

    return false if token.blank?

    rss_token = RssToken.find_by(token: token)
    return false unless rss_token

    @game.active_members.exists?(user_id: rss_token.user_id)
  end

  sig { returns(ActionController::Parameters) }
  def summary_params
    params.require(:scene_summary).permit(:body)
  end
end
