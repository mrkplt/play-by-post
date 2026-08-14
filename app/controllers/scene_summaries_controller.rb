# typed: strict

class SceneSummariesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!, only: %i[index new create edit update destroy]
  before_action :set_scene, only: %i[new create edit update destroy]
  before_action :require_resolved_scene!, only: %i[new create]
  before_action :set_summary, only: %i[edit update destroy]
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    pagy, summaries = pagy(SceneSummary.public_for_game(T.must(@game)), limit: 20)
    @summaries_presenter = T.let(
      SceneSummaryCollectionPresenter.new(summaries, game: @game, urls: self, pagy: pagy),
      T.nilable(SceneSummaryCollectionPresenter)
    )
    @game_presenter = T.let(GamePresenter.new(T.must(@game), policy: policy(@game)), T.nilable(GamePresenter))
  end

  sig { void }
  def new
    summary = T.must(@scene).build_scene_summary
    authorize summary
    assign_presenters(summary)
  end

  sig { void }
  def create
    authorize SceneSummary.new(scene_id: T.must(@scene).id), :create?
    if T.must(@scene).scene_summary.present?
      redirect_to edit_game_scene_scene_summary_path(@game, @scene),
                  alert: "A summary already exists. Edit it instead."
      return
    end

    summary = T.must(@scene).build_scene_summary(summary_params.merge(edited_by: current_user, edited_at: Time.current))
    if summary.save
      redirect_to game_scene_path(@game, @scene), notice: "Summary saved."
    else
      assign_presenters(summary)
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def edit
    authorize @summary
    assign_presenters(T.must(@summary))
  end

  sig { void }
  def update
    authorize @summary
    attrs = summary_params.merge(edited_by: current_user, edited_at: Time.current,
                                 generated_at: nil, model_used: nil,
                                 input_tokens: nil, output_tokens: nil)
    if T.must(@summary).update(attrs)
      redirect_to game_scene_path(@game, @scene), notice: "Summary updated."
    else
      assign_presenters(T.must(@summary))
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize @summary
    T.must(@summary).destroy!
    redirect_to game_scene_path(@game, @scene), notice: "Summary deleted."
  end

  private

  # Populates the game/summary presenter pair every new/edit/error render needs.
  sig { params(summary: SceneSummary).void }
  def assign_presenters(summary)
    @game_presenter = T.let(GamePresenter.new(T.must(@game), policy: policy(@game)), T.nilable(GamePresenter))
    @summary_presenter = T.let(
      SceneSummaryPresenter.new(summary, game: @game, urls: self, policy: policy(summary)),
      T.nilable(SceneSummaryPresenter)
    )
  end

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_scene
    @scene = T.let(T.must(@game).scenes.find(params[:scene_id]), T.nilable(Scene))
  end

  sig { void }
  def set_summary
    @summary = T.let(T.must(@scene).scene_summary, T.nilable(SceneSummary))
    redirect_to game_scene_path(@game, @scene), alert: "No summary found." unless @summary
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end

  sig { void }
  def require_resolved_scene!
    return if T.must(@scene).resolved?

    redirect_to game_scene_path(@game, @scene), alert: "Summaries are only available for resolved scenes."
  end

  sig { returns(ActionController::Parameters) }
  def summary_params
    params.require(:scene_summary).permit(:body)
  end
end
