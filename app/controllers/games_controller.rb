# typed: strict

class GamesController < ApplicationController
  extend T::Sig

  before_action :require_game_access!, only: %i[show]
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    dashboard = GameDashboardQuery.new(current_user, ->(record) { policy(record) })

    @dashboard_presenter = T.let(dashboard.presenter, T.nilable(GameDashboardPresenter))
  end

  sig { void }
  def new
    game = Game.new
    authorize game
    assign_game_presenter(game)
  end

  sig { void }
  def create
    new_game = Game.new(game_params)
    authorize new_game
    return render_form(new_game, :new) unless new_game.save

    new_game.game_members.create!(user: current_user, role: "game_master", status: "active")
    redirect_to new_game, notice: "Game created."
  end

  sig { void }
  def show
    authorize game
    @game_screen = T.let(build_game_screen, T.nilable(GameScreenPresenter))
  end

  sig { void }
  def edit
    authorize game
    assign_game_presenter(game)
  end

  sig { void }
  def update
    target = game
    authorize target
    return render_form(target, :edit) unless target.update(game_params)

    redirect_to game_player_management_path(target), notice: "Game updated."
  end

  sig { void }
  def destroy
    authorize game
    game.soft_delete!
    redirect_to root_path, notice: "\"#{game.name}\" has been deleted."
  end

  private

  sig { params(record: Game).void }
  def assign_game_presenter(record)
    @game_presenter = T.let(GamePresenter.new(record, policy: policy(record)), T.nilable(GamePresenter))
  end

  # Holds the invalid record, not a fresh one, so the user sees what they typed.
  sig { params(record: Game, template: Symbol).void }
  def render_form(record, template)
    assign_game_presenter(record)
    render template, status: :unprocessable_content
  end

  sig { returns(GameScreenPresenter) }
  def build_game_screen
    viewer = GameScreenPresenter::Viewer.new(current_user: current_user, urls: self, helpers: helpers)
    presenter = GamePresenter.new(
      game, policy: policy(game), current_user: current_user, urls: self, helpers: helpers
    )

    GameScreenPresenter.build(presenter, viewer)
  end

  # Looked up on demand rather than cached in a before_action ivar: no
  # template reads it directly (only @game_presenter's output does), so
  # nothing needs it to persist as request state.
  sig { returns(Game) }
  def game
    Game.find_by!(slug: params[:id])
  end

  # Not redundant with `authorize`: this gates before the action runs and gives
  # "cannot see this game at all" its own message, distinct from a denial of
  # the specific thing being attempted.
  sig { void }
  def require_game_access!
    return if policy(game).view?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  sig { returns(ActionController::Parameters) }
  def game_params
    params.require(:game).permit(:name, :description, :post_edit_window_minutes)
  end
end
