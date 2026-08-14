# typed: strict

class GamesController < ApplicationController
  extend T::Sig

  before_action :require_game_access!, only: %i[show]
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    memberships = dashboard_memberships

    @dashboard_presenter = T.let(
      GameDashboardPresenter.new(
        memberships,
        current_user: current_user,
        policy_by_game_id: policy_by_game_id(memberships),
        games_with_new_activity: games_with_new_activity(memberships)
      ),
      T.nilable(GameDashboardPresenter)
    )
  end

  sig { void }
  def new
    game = Game.new
    authorize game
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
  end

  sig { void }
  def create
    game = Game.new(game_params)
    authorize game
    if game.save
      game.game_members.create!(user: current_user, role: "game_master", status: "active")
      redirect_to game, notice: "Game created."
    else
      @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_sheets_hidden
    authorize game, :manage?
    game.update!(sheets_hidden: !game.sheets_hidden?)
    redirect_to game_path(game), notice: game.sheets_hidden? ? "Character sheets are now hidden." : "Character sheets are now visible."
  end

  sig { void }
  def toggle_images_disabled
    authorize game, :manage?
    game.update!(images_disabled: !game.images_disabled?)
    redirect_to edit_game_path(game), notice: game.images_disabled? ? "Image attachments are now disabled." : "Image attachments are now enabled."
  end

  sig { void }
  # mutant:disable
  def toggle_ai_summaries_enabled
    authorize game, :manage?
    game.update!(ai_summaries_enabled: !game.ai_summaries_enabled?)
    redirect_to game_player_management_path(game), notice: game.ai_summaries_enabled? ? "AI scene summaries enabled." : "AI scene summaries disabled."
  end

  sig { void }
  def show
    authorize game
    @game_presenter = T.let(
      GamePresenter.new(game, policy: policy(game), current_user: current_user, urls: self, helpers: helpers),
      T.nilable(GamePresenter)
    )
    @game_show = T.let(
      GameShowPresenter.new(T.must(@game_presenter), current_user: current_user, urls: self, helpers: helpers),
      T.nilable(GameShowPresenter)
    )
    @game_roster = T.let(
      GameRosterPresenter.new(T.must(@game_presenter), current_user: current_user, urls: self),
      T.nilable(GameRosterPresenter)
    )
    @game_scenes = T.let(
      GameScenesPanelPresenter.new(T.must(@game_presenter), current_user: current_user),
      T.nilable(GameScenesPanelPresenter)
    )
  end

  sig { void }
  def edit
    authorize game
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
  end

  sig { void }
  def update
    authorize game
    if game.update(game_params)
      redirect_to game_player_management_path(game), notice: "Game updated."
    else
      @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
      render :edit, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize game
    game.soft_delete!
    redirect_to root_path, notice: "\"#{game.name}\" has been deleted."
  end

  private

  # Active/former memberships for the dashboard, oldest-game-name first.
  # Memberships whose game was soft-deleted are dropped: the default scope
  # makes membership.game nil for those, so they must not reach the dashboard
  # loop. Game.all carries the default scope, so this is IN (kept game ids).
  sig { returns(T::Array[GameMember]) }
  def dashboard_memberships
    current_user.game_members
      .where.not(status: "banned")
      .where(game_id: Game.all)
      .includes(game: %i[scenes])
      .order("games.name")
      .to_a
  end

  # Pundit's policy per game, built once in the controller (where policies
  # belong) rather than looked up per-item in the presenter (R2). Each
  # GameDashboardItemPresenter wraps its game in a GamePresenter carrying
  # this same policy, so the card's crown and the "can_manage" flag can
  # never disagree.
  sig { params(memberships: T::Array[GameMember]).returns(T::Hash[Integer, GamePolicy]) }
  def policy_by_game_id(memberships)
    memberships.each_with_object({}) do |membership, hash|
      game = membership.game
      next if game.nil?

      hash[game.id] = policy(game)
    end
  end

  # Ids of games with a post newer than the viewer's last login — the dashboard
  # card's "new activity" glow.
  sig { params(memberships: T::Array[GameMember]).returns(T::Array[Integer]) }
  def games_with_new_activity(memberships)
    last_login_at = current_user.user_profile&.last_login_at
    game_ids = memberships.filter_map(&:game_id)
    return [] unless last_login_at && game_ids.any?

    Post.joins(:scene)
      .where(scenes: { game_id: game_ids })
      .where("posts.created_at > ?", last_login_at)
      .distinct
      .pluck("scenes.game_id")
  end

  # Looked up on demand rather than cached in a before_action ivar: no
  # template reads it directly (only @game_presenter's output does), so
  # nothing needs it to persist as request state.
  sig { returns(Game) }
  def game
    Game.find(params[:id])
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
