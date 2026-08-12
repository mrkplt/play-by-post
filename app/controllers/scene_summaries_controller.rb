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
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    unless user_signed_in? && game_access_granted?
      redirect_to new_user_session_path
      return
    end
    summaries = scene_summaries_for_game
    @pagy, @summaries = pagy(summaries, limit: 20)
    @game_presenter = GamePresenter.new(@game, current_user)
  end

  sig { void }
  def new
    @summary = @scene.build_scene_summary
    authorize @summary
  end

  sig { void }
  def create
    authorize SceneSummary.new(scene_id: @scene.id), :create?
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
    authorize @summary
  end

  sig { void }
  def update
    authorize @summary
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
    authorize @summary
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
    policy(@game).show?
  end

  sig { void }
  def require_gm!
    return if policy(@game).update?

    redirect_to @game, alert: "Only the GM can manage summaries."
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

  sig { returns(ActionController::Parameters) }
  def summary_params
    params.require(:scene_summary).permit(:body)
  end
end
