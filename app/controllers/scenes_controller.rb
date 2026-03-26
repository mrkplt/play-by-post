class ScenesController < ApplicationController
  before_action :set_game
  before_action :require_game_access!
  before_action :require_gm!, only: %i[new create]
  before_action :set_scene, only: %i[show resolve toggle_notification_preference]

  def index
    all_scenes = @game.scenes
      .visible_to(current_user, @game)
      .includes(:parent_scene, :child_scenes, scene_participants: [ :character, :user ])
      .order(created_at: :asc)
      .to_a

    scene_index = all_scenes.index_by(&:id)
    roots = all_scenes.select { |s| s.parent_scene_id.nil? || scene_index[s.parent_scene_id].nil? }

    @trees = roots.map { |root| build_tree(root, scene_index, all_scenes) }
    @is_gm = @game.game_master?(current_user)
  end

  def new
    @scene = @game.scenes.new
    @players_with_characters = active_players_with_characters
    @parent_scene_options = parent_scene_options
  end

  def create
    @scene = @game.scenes.new(scene_params)

    if @scene.save
      add_participants
      notify_new_scene
      redirect_to game_scene_path(@game, @scene), notice: "Scene created."
    else
      @players_with_characters = active_players_with_characters
      @parent_scene_options = parent_scene_options
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @posts = @scene.posts.includes(:user).order(:created_at)
    @post = Post.new
    @is_gm = @game.game_master?(current_user)
    @is_participant = @scene.participant?(current_user)
    @current_membership = @game.member_for(current_user)
    @is_muted = NotificationPreference.muted?(@scene, current_user)
    @hide_ooc = current_user.user_profile&.hide_ooc? || false
    @child_scenes = @scene.child_scenes.visible_to(current_user, @game).order(:created_at)

    if @is_participant || @is_gm
      @scene.scene_participants.find_by(user: current_user)
        &.update(last_visited_at: Time.current)
    end
  end

  def toggle_notification_preference
    NotificationPreference.toggle!(@scene, current_user)
    redirect_to game_scene_path(@game, @scene),
      notice: NotificationPreference.muted?(@scene, current_user) ? "Notifications muted for this scene." : "Notifications enabled for this scene."
  end

  def resolve
    unless @game.game_master?(current_user)
      redirect_to game_scene_path(@game, @scene), alert: "Only the GM can resolve a scene."
      return
    end

    if @scene.resolved?
      redirect_to game_scene_path(@game, @scene), alert: "Scene is already resolved."
      return
    end

    @scene.update!(resolved_at: Time.current, resolution: params[:resolution])
    notify_scene_resolved
    redirect_to game_scene_path(@game, @scene), notice: "Scene resolved."
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def set_scene
    @scene = @game.scenes.find(params[:id])
    check_scene_visibility!
  end

  def check_scene_visibility!
    return if @game.game_master?(current_user)
    return unless @scene.private?
    return if @scene.participant?(current_user)

    redirect_to game_path(@game), alert: "You do not have access to this scene."
  end

  def require_game_access!
    membership = @game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  def require_gm!
    return if @game.game_master?(current_user)

    redirect_to game_path(@game), alert: "Only the GM can create scenes."
  end

  # Returns an array of [user, characters] pairs for all active players,
  # including players with no characters (empty array).
  def active_players_with_characters
    players = @game.users.joins(:game_members)
      .where(game_members: { game: @game, role: "player", status: "active" })
      .order("user_profiles.display_name")
      .joins("LEFT JOIN user_profiles ON user_profiles.user_id = users.id")

    characters_by_user = @game.characters.active
      .joins("INNER JOIN game_members ON game_members.user_id = characters.user_id AND game_members.game_id = #{@game.id}")
      .where(game_members: { role: "player", status: "active" })
      .order(:name)
      .group_by(&:user_id)

    players.map { |user| [ user, characters_by_user.fetch(user.id, []) ] }
  end

  def notify_new_scene
    @scene.users.where.not(id: current_user.id).each do |recipient|
      next if NotificationPreference.muted?(@scene, recipient)
      NotificationMailer.new_scene(@scene, recipient).deliver_later
    end
  end

  def notify_scene_resolved
    @scene.users.each do |recipient|
      next if NotificationPreference.muted?(@scene, recipient)
      NotificationMailer.scene_resolved(@scene, recipient).deliver_later
    end
  end

  def add_participants
    gm = @game.game_master

    # Always add the GM as a user-only (no character) participant
    @scene.scene_participants.find_or_create_by!(user_id: gm.id)

    # Add each selected character, deriving user from character.user
    Array(params[:character_ids]).map(&:to_i).each do |cid|
      character = @game.characters.find_by(id: cid)
      next unless character
      @scene.scene_participants.find_or_create_by!(user_id: character.user_id) do |sp|
        sp.character = character
      end
    end
  end

  def parent_scene_options
    active = @game.scenes.active.order(created_at: :desc).to_a
    recent_resolved = @game.scenes.resolved.order(resolved_at: :desc).limit(3).to_a
    (active + recent_resolved)
  end

  def build_tree(scene, scene_index, all_scenes)
    children = all_scenes
      .select { |s| s.parent_scene_id == scene.id }
      .sort_by(&:created_at)
    {
      scene: scene,
      children: children.map { |c| build_tree(c, scene_index, all_scenes) }
    }
  end

  def scene_params
    params.require(:scene).permit(:title, :private, :parent_scene_id, :image)
  end
end
