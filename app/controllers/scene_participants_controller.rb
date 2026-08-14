# typed: strict

class SceneParticipantsController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :set_scene
  before_action :require_active_member_for_write!, only: %i[join]
  after_action :verify_authorized

  sig { void }
  def edit
    authorize @scene, :manage_participants?
    @game_presenter = T.let(
      GamePresenter.new(T.must(@game), policy: policy(@game)), T.nilable(GamePresenter)
    )
    players = T.must(@game).users.joins(:game_members)
      .where(game_members: { game: @game, role: "player", status: "active" })
      .order("user_profiles.display_name")
      .joins("LEFT JOIN user_profiles ON user_profiles.user_id = users.id")

    characters_by_user = T.must(@game).characters.active
      .joins("INNER JOIN game_members ON game_members.user_id = characters.user_id AND game_members.game_id = #{T.must(@game).id}")
      .where(game_members: { role: "player", status: "active" })
      .order(:name)
      .group_by(&:user_id)

    @players_with_characters = T.let(
      players.map { |user| ScenePlayerPresenter.new(user, characters: characters_by_user.fetch(user.id, [])) },
      T.nilable(T::Array[ScenePlayerPresenter])
    )
    selected_ids = T.must(@scene).scene_participants.where.not(character_id: nil).pluck(:character_id)
    @current_character_ids = T.let(
      SceneParticipantRosterPresenter.new(selected_ids), T.nilable(SceneParticipantRosterPresenter)
    )
  end

  sig { void }
  def update
    authorize @scene, :manage_participants?
    gm = T.must(@game).game_master
    character_ids = Array(params[:character_ids]).map(&:to_i)
    characters = T.must(@game).characters.where(id: character_ids)
    player_user_ids = characters.map(&:user_id)

    # Remove player rows not in the new set; always keep GM row
    T.must(@scene).scene_participants.where.not(user_id: T.must(gm).id).where.not(user_id: player_user_ids).destroy_all

    # Ensure GM row exists (no character)
    T.must(@scene).scene_participants.find_or_create_by!(user_id: T.must(gm).id)

    # Upsert each selected character
    characters.each do |character|
      sp = T.must(@scene).scene_participants.find_or_initialize_by(user_id: character.user_id)
      sp.character = character
      sp.save!
    end

    redirect_to game_scene_path(@game, @scene), notice: "Participants updated."
  end

  sig { void }
  def join
    authorize @scene, :join?
    if T.must(@scene).private? && !policy(@scene).visible?
      redirect_to game_scene_path(@game, @scene), alert: "Cannot join a private scene."
      return
    end

    if T.must(@scene).resolved?
      redirect_to game_scene_path(@game, @scene), alert: "Cannot join a resolved scene."
      return
    end

    T.must(@scene).scene_participants.find_or_create_by!(user: current_user)
    redirect_to game_scene_path(@game, @scene), notice: "You have joined this scene."
  end

  private

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_scene
    @scene = T.let(T.must(@game).scenes.find(params[:scene_id]), T.nilable(Scene))
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(T.must(@game))
  end
end
