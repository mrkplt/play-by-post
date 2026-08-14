# typed: strict

class SceneSummariesController < ApplicationController
  extend T::Sig
  include SceneSummaryScoped

  before_action :set_game
  before_action :require_game_access!, only: %i[index new create edit update destroy]
  before_action :set_scene, only: %i[new create edit update destroy]
  before_action :require_resolved_scene!, only: %i[new create]
  before_action :set_summary, only: %i[edit update destroy]
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    pagy, summaries = pagy(SceneSummary.public_for_game(game), limit: 20)
    @summaries_presenter = T.let(
      SceneSummaryCollectionPresenter.new(summaries, game: game, urls: self, pagy: pagy),
      T.nilable(SceneSummaryCollectionPresenter)
    )
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter))
  end

  sig { void }
  def new
    new_summary = scene.build_scene_summary
    authorize new_summary
    assign_presenters(new_summary)
  end

  sig { void }
  def create
    authorize SceneSummary.new(scene_id: scene.id), :create?
    if scene.scene_summary.present?
      return redirect_to edit_game_scene_scene_summary_path(game, scene),
                          alert: "A summary already exists. Edit it instead."
    end

    new_summary = scene.build_scene_summary(summary_params.merge(edited_by: current_user, edited_at: Time.current))
    if new_summary.save
      redirect_to game_scene_path(game, scene), notice: "Summary saved."
    else
      assign_presenters(new_summary)
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def edit
    authorize summary
    assign_presenters(T.must(summary))
  end

  sig { void }
  def update
    authorize summary
    found_summary = T.must(summary)
    if found_summary.apply_manual_edit(body: summary_params[:body], editor: current_user)
      redirect_to game_scene_path(game, scene), notice: "Summary updated."
    else
      assign_presenters(found_summary)
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize summary
    T.must(summary).destroy!
    redirect_to game_scene_path(game, scene), notice: "Summary deleted."
  end

  private

  # Populates the game/summary presenter pair every new/edit/error render needs.
  sig { params(found_summary: SceneSummary).void }
  def assign_presenters(found_summary)
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter))
    @summary_presenter = T.let(
      SceneSummaryPresenter.new(found_summary, game: game, urls: self, policy: policy(found_summary)),
      T.nilable(SceneSummaryPresenter)
    )
  end

  # Overrides SceneSummaryScoped#set_summary to add the not-found redirect
  # this controller's #edit/#update/#destroy need — the lookup itself stays
  # in the shared module.
  sig { void }
  def set_summary
    super
    redirect_to game_scene_path(game, scene), alert: "No summary found." unless summary
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end

  sig { void }
  def require_resolved_scene!
    return if scene.resolved?

    redirect_to game_scene_path(game, scene), alert: "Summaries are only available for resolved scenes."
  end

  sig { returns(ActionController::Parameters) }
  def summary_params
    params.require(:scene_summary).permit(:body)
  end
end
