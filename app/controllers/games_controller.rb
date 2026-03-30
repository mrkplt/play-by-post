class GamesController < ApplicationController
  before_action :set_game, only: %i[show edit update toggle_sheets_hidden]
  before_action :require_game_access!, only: %i[show]
  before_action :require_gm!, only: %i[edit update toggle_sheets_hidden]

  def index
    @memberships = current_user.game_members
      .where.not(status: "banned")
      .includes(game: %i[scenes])
      .order("games.name")

    @dashboard_items = @memberships.map do |membership|
      game = membership.game
      active_scenes = game.scenes.where(resolved_at: nil).count
      primary_character = game.characters.active.find_by(user: current_user)
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

  def toggle_sheets_hidden
    @game.update!(sheets_hidden: !@game.sheets_hidden?)
    redirect_to game_path(@game), notice: @game.sheets_hidden? ? "Character sheets are now hidden." : "Character sheets are now visible."
  end

  def show
    @active_scenes = @game.scenes
      .visible_to(current_user, @game)
      .active
      .includes(:parent_scene, :child_scenes, :posts, scene_participants: [ :character, :user ])
      .to_a
      .sort_by { |s| -s.last_activity_at.to_i }

    @is_gm = @game.game_master?(current_user)
    @characters = @game.characters.active.visible_to(current_user, @game).includes(:user).order(:name)
    @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
  end

  def edit
  end

  def update
    if @game.update(game_params)
      redirect_to @game, notice: "Game updated."
    else
      render :edit, status: :unprocessable_entity
    end
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

  def require_gm!
    return if @game.game_master?(current_user)

    redirect_to game_path(@game), alert: "Only the GM can do this."
  end

  def game_params
    params.require(:game).permit(:name, :description)
  end
end
