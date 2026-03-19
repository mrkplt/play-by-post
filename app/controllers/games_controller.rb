class GamesController < ApplicationController
  before_action :set_game, only: %i[show]
  before_action :require_game_access!, only: %i[show]

  def index
    @memberships = current_user.game_members
      .where.not(status: "banned")
      .includes(game: %i[scenes])
      .order("games.name")

    @dashboard_items = @memberships.map do |membership|
      game = membership.game
      active_scenes = game.scenes.where(resolved_at: nil).count
      primary_character = game.characters.find_by(user: current_user, active: true)
      {
        game: game,
        membership: membership,
        active_scene_count: active_scenes,
        primary_character: primary_character
      }
    end
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    if @game.save
      @game.game_members.create!(user: current_user, role: "game_master", status: "active")
      redirect_to @game, notice: "Game created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    active_scenes = @game.scenes.active
      .visible_to(current_user, @game)
      .includes(:scene_participants, :users, :parent_scene)
      .order(created_at: :desc)

    # Group parallel scenes (same parent) together
    @scene_groups = active_scenes.group_by(&:parent_scene_id).values

    @pagy_resolved, @resolved_scenes = pagy(
      @game.scenes.resolved
        .visible_to(current_user, @game)
        .order(resolved_at: :desc),
      items: 10
    )

    @is_gm = @game.game_master?(current_user)
    @characters = @game.characters.active.visible_to(current_user, @game).includes(:user).order(:name)
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def require_game_access!
    membership = @game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  def game_params
    params.require(:game).permit(:name, :description)
  end
end
