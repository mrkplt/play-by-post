# typed: true

class GamesController < ApplicationController
  extend T::Sig

  before_action :set_game, only: %i[show edit update toggle_sheets_hidden toggle_images_disabled toggle_ai_summaries_enabled]
  before_action :require_game_access!, only: %i[show]
  before_action :require_gm!, only: %i[edit update toggle_sheets_hidden toggle_images_disabled toggle_ai_summaries_enabled]
  after_action :verify_authorized, except: :index

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
      additional_character_count = [ user_characters.length - 1, 0 ].max
      {
        game: game,
        membership: membership,
        active_scene_count: active_scenes,
        primary_character: primary_character,
        additional_character_count: additional_character_count,
        character_label: character_label_for(primary_character, additional_character_count),
        is_gm: membership.game_master?,
        former: membership.removed?,
        new_activity: games_with_new_activity.include?(game.id)
      }
    end
  end

  sig { void }
  def new
    @game = Game.new
    authorize @game
  end

  sig { void }
  def create
    @game = Game.new(game_params)
    authorize @game
    if @game.save
      @game.game_members.create!(user: current_user, role: "game_master", status: "active")
      redirect_to @game, notice: "Game created."
    else
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def toggle_sheets_hidden
    authorize @game, :update?
    @game.update!(sheets_hidden: !@game.sheets_hidden?)
    redirect_to game_path(@game), notice: @game.sheets_hidden? ? "Character sheets are now hidden." : "Character sheets are now visible."
  end

  sig { void }
  def toggle_images_disabled
    authorize @game, :update?
    @game.update!(images_disabled: !@game.images_disabled?)
    redirect_to edit_game_path(@game), notice: @game.images_disabled? ? "Image attachments are now disabled." : "Image attachments are now enabled."
  end

  sig { void }
  # mutant:disable
  def toggle_ai_summaries_enabled
    authorize @game, :update?
    @game.update!(ai_summaries_enabled: !@game.ai_summaries_enabled?)
    redirect_to game_player_management_path(@game), notice: @game.ai_summaries_enabled? ? "AI scene summaries enabled." : "AI scene summaries disabled."
  end

  sig { void }
  def show
    authorize @game
    raw_scenes = @game.scenes
      .visible_to(current_user, @game)
      .active
      .includes(:parent_scene, :child_scenes, :posts, scene_participants: [ :character, :user ])
      .to_a
      .sort_by { |s| -s.last_activity_at.to_i }
    @active_scenes = raw_scenes.map { |s| ScenePresenter.new(s) }

    @game_presenter = GamePresenter.new(@game, current_user)
    @gm_name = gm_display_name
    @roster_preview = roster_preview_rows(raw_scenes)
    @hot_scene_ids = hot_scene_ids(raw_scenes)

    # Roster tab
    characters = @game.characters.active.visible_to(current_user, @game).includes(:user).order(:name).to_a
    removed_user_ids = @game.game_members.where(status: "removed").pluck(:user_id).to_set
    @roster_characters = characters.map do |c|
      owner_name = UserPresenter.new(c.user).display_name_or_email
      removed = removed_user_ids.include?(c.user_id)
      {
        character: c,
        owner_name: owner_name,
        removed: removed,
        avatar_tone: removed ? :muted : :gold,
        filter_key: "#{c.name} #{owner_name}".downcase
      }
    end
    @inactive_count = @game.characters.archived.visible_to(current_user, @game).count
    @banned_members = policy(@game).update? ? @game.game_members.where(status: "banned").includes(:user).to_a : []
    @banned_names = @banned_members.each_with_object({}) do |m, h|
      h[m.user_id] = UserPresenter.new(m.user).display_name_or_email
    end
    @pending_invitations = policy(@game).update? ? @game.invitations.pending.order(created_at: :desc).to_a : []

    # Files tab
    @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
    @game_file = @game.game_files.new
  end

  sig { void }
  def edit
    authorize @game
  end

  sig { void }
  def update
    authorize @game
    if @game.update(game_params)
      redirect_to @game, notice: "Game updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # "Vex Marrowgate +1" — primary character plus a count of the rest, or nil
  # when the player has no character in the game.
  sig { params(primary: T.nilable(Character), extra: Integer).returns(T.nilable(String)) }
  def character_label_for(primary, extra)
    return nil if primary.nil?

    extra.positive? ? "#{primary.name} +#{extra}" : primary.name
  end

  sig { returns(String) }
  def gm_display_name
    gm = @game.game_members.game_masters.includes(:user).first&.user
    gm ? UserPresenter.new(gm).display_name_or_email : "GM"
  end

  # The "In Active Scenes" roster preview: the GM, then each character
  # participating in an active scene paired with that scene's title. Banned
  # players are already excluded from scene participation.
  sig { params(scenes: T::Array[Scene]).returns(T::Array[T::Hash[Symbol, String]]) }
  def roster_preview_rows(scenes)
    rows = scenes.flat_map do |scene|
      scene.scene_participants.filter_map do |sp|
        next unless sp.character

        { name: T.must(sp.character).name, scene: scene.title }
      end
    end
    rows.uniq { |r| r[:name] }.first(5)
  end

  # Scenes with activity since the viewer last logged in get the attention glow.
  sig { params(scenes: T::Array[Scene]).returns(T::Set[Integer]) }
  def hot_scene_ids(scenes)
    last_login = current_user.user_profile&.last_login_at
    return Set.new unless last_login

    Set.new(scenes.select { |s| s.last_activity_at.to_i > last_login.to_i }.map(&:id))
  end

  sig { void }
  def set_game
    @game = Game.find(params[:id])
  end

  sig { void }
  def require_game_access!
    return if policy(@game).show?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  sig { void }
  def require_gm!
    return if policy(@game).update?

    redirect_to game_path(@game), alert: "Only the GM can do this."
  end

  sig { returns(ActionController::Parameters) }
  def game_params
    params.require(:game).permit(:name, :description, :post_edit_window_minutes)
  end
end
