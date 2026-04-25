# typed: true

class GamesController < ApplicationController
  extend T::Sig

  before_action :set_game, only: %i[show edit update toggle_sheets_hidden toggle_images_disabled]
  before_action :require_game_access!, only: %i[show]
  before_action :require_gm!, only: %i[edit update toggle_sheets_hidden toggle_images_disabled]

  sig { void }
  def index
    @memberships = current_user.game_members
      .where.not(status: "banned")
      .includes(game: %i[scenes])
      .order("games.name")

    last_login_at = current_user.user_profile&.last_login_at
    game_ids = @memberships.filter_map(&:game_id)

    games_with_new_activity = if last_login_at && game_ids.any?
      Post.joins(:scene)
        .where(scenes: { game_id: game_ids })
        .where("posts.created_at > ?", last_login_at)
        .distinct
        .pluck("scenes.game_id")
    else
      []
    end

    @dashboard_items = @memberships.map do |membership|
      game = T.must(membership.game)
      active_scenes = game.scenes.where(resolved_at: nil).count
      user_characters = game.characters.active.where(user: current_user).to_a
      primary_character = user_characters.first
      additional_character_count = [user_characters.length - 1, 0].max
      {
        game: game,
        membership: membership,
        active_scene_count: active_scenes,
        primary_character: primary_character,
        additional_character_count: additional_character_count,
        new_activity: games_with_new_activity.include?(game.id)
      }
    end
  end

  sig { void }
  def new
    @game = Game.new
  end

  sig { void }
  def create
    @game = Game.new(game_params)
    if @game.save
      @game.game_members.create!(user: current_user, role: "game_master", status: "active")
      redirect_to @game, notice: "Game created."
    else
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_sheets_hidden
    @game.update!(sheets_hidden: !@game.sheets_hidden?)
    redirect_to game_path(@game), notice: @game.sheets_hidden? ? "Character sheets are now hidden." : "Character sheets are now visible."
  end

  sig { void }
  def toggle_images_disabled
    @game.update!(images_disabled: !@game.images_disabled?)
    redirect_to edit_game_path(@game), notice: @game.images_disabled? ? "Image attachments are now disabled." : "Image attachments are now enabled."
  end

  sig { void }
  def show
    raw_scenes = @game.scenes
      .visible_to(current_user, @game)
      .active
      .includes(:parent_scene, :child_scenes, :posts, scene_participants: [ :character, :user ])
      .to_a
      .sort_by { |s| -s.last_activity_at.to_i }
    @active_scenes = raw_scenes.map { |s| ScenePresenter.new(s) }

    @is_gm = @game.game_master?(current_user)
    @characters = @game.characters.active.visible_to(current_user, @game).includes(:user).order(:name)
    @character_owner_names = @characters.each_with_object({}) { |c, h| h[c.id] = UserPresenter.new(c.user).display_name_or_email }
    @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
    @export_rate_limited = GameExportRequest.rate_limited?(current_user, @game)
  end

  sig { void }
  def edit
  end

  sig { void }
  def update
    if @game.update(game_params)
      redirect_to @game, notice: "Game updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:id])
  end

  sig { void }
  def require_game_access!
    membership = @game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  sig { void }
  def require_gm!
    return if @game.game_master?(current_user)

    redirect_to game_path(@game), alert: "Only the GM can do this."
  end

  sig { returns(ActionController::Parameters) }
  def game_params
    params.require(:game).permit(:name, :description, :post_edit_window_minutes)
  end
end
