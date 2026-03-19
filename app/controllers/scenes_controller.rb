class ScenesController < ApplicationController
  before_action :set_game
  before_action :require_game_access!
  before_action :set_scene, only: %i[show resolve toggle_notification_preference]

  def new
    @scene = @game.scenes.new
    @participants = active_game_users
  end

  def create
    @scene = @game.scenes.new(scene_params)

    if @scene.save
      add_participants
      notify_new_scene
      redirect_to game_scene_path(@game, @scene), notice: "Scene created."
    else
      @participants = active_game_users
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @posts = @scene.posts.includes(:user).order(:created_at)
    @post = Post.new
    @is_gm = @game.game_master?(current_user)
    @is_participant = @scene.participant?(current_user)
    @is_muted = NotificationPreference.muted?(@scene, current_user)

    # Update last_visited_at
    if @is_participant
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

  def active_game_users
    @game.users.joins(:game_members)
      .where(game_members: { game: @game, status: "active" })
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
    user_ids = (Array(params[:participant_ids]) + [ gm.id, current_user.id ]).map(&:to_i).uniq
    user_ids.each do |uid|
      @scene.scene_participants.find_or_create_by!(user_id: uid)
    end
  end

  def scene_params
    params.require(:scene).permit(:title, :description, :private, :parent_scene_id)
  end
end
