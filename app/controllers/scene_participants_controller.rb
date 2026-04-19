# typed: true

class SceneParticipantsController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :set_scene
  before_action :require_gm!, only: %i[edit update]
  before_action :require_active_member_for_write!, only: %i[join]

  sig { void }
  def edit
    players = @game.users.joins(:game_members)
      .where(game_members: { game: @game, role: "player", status: "active" })
      .order("user_profiles.display_name")
      .joins("LEFT JOIN user_profiles ON user_profiles.user_id = users.id")

    characters_by_user = @game.characters.active
      .joins("INNER JOIN game_members ON game_members.user_id = characters.user_id AND game_members.game_id = #{@game.id}")
      .where(game_members: { role: "player", status: "active" })
      .order(:name)
      .group_by(&:user_id)

    @players_with_characters = players.map { |user| [ UserPresenter.new(user), characters_by_user.fetch(user.id, []) ] }
    @current_character_ids = @scene.scene_participants.where.not(character_id: nil).pluck(:character_id)
  end

  sig { void }
  def update
    gm = T.must(@game.game_master)
    character_ids = Array(params[:character_ids]).map(&:to_i)
    characters = @game.characters.where(id: character_ids)
    player_user_ids = characters.map(&:user_id)

    # Remove player rows not in the new set; always keep GM row
    @scene.scene_participants.where.not(user_id: gm.id).where.not(user_id: player_user_ids).destroy_all

    # Ensure GM row exists (no character)
    @scene.scene_participants.find_or_create_by!(user_id: gm.id)

    # Upsert each selected character
    characters.each do |character|
      sp = @scene.scene_participants.find_or_initialize_by(user_id: character.user_id)
      sp.character = character
      sp.save!
    end

    redirect_to game_scene_path(@game, @scene), notice: "Participants updated."
  end

  sig { void }
  def join
    if @scene.private? && !@game.game_master?(current_user)
      redirect_to game_scene_path(@game, @scene), alert: "Cannot join a private scene."
      return
    end

    if @scene.resolved?
      redirect_to game_scene_path(@game, @scene), alert: "Cannot join a resolved scene."
      return
    end

    @scene.scene_participants.find_or_create_by!(user: current_user)
    redirect_to game_scene_path(@game, @scene), notice: "You have joined this scene."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def set_scene
    @scene = @game.scenes.find(params[:scene_id])
  end

  sig { void }
  def require_gm!
    return if @game.game_master?(current_user)

    redirect_to game_scene_path(@game, @scene), alert: "Only the GM can edit participants."
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(@game)
  end
end
