# typed: strict

class SceneParticipantsController < ApplicationController
  extend T::Sig
  include SceneParticipantScoped

  before_action :require_active_member_for_write!, only: %i[join]
  after_action :verify_authorized

  sig { void }
  def edit
    authorize scene, :manage_participants?
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game), urls: self), T.nilable(GamePresenter))
    @scene_presenter = T.let(ScenePresenter.new(scene, game: game, urls: self), T.nilable(ScenePresenter))
    @scene_navigation_presenter = T.let(
      SceneNavigationPresenter.new(T.must(@scene_presenter), game: game, urls: self),
      T.nilable(SceneNavigationPresenter)
    )
    @players_with_characters = T.let(players_with_characters, T.nilable(T::Array[ScenePlayerPresenter]))
    @current_character_ids = T.let(current_character_ids_presenter, T.nilable(SceneParticipantRosterPresenter))
  end

  sig { void }
  def update
    authorize scene, :manage_participants?
    characters = game.characters.where(id: Array(params[:character_ids]).map(&:to_i))
    SceneParticipantSync.call(scene: scene, characters: characters)

    redirect_to game_scene_path(game, scene), notice: "Participants updated."
  end

  sig { void }
  def join
    authorize scene, :join?
    blocker = join_blocker
    return redirect_to game_scene_path(game, scene), alert: blocker if blocker

    join_scene
  end

  private

  sig { void }
  def join_scene
    scene.scene_participants.find_or_create_by!(user: current_user)
    redirect_to game_scene_path(game, scene), notice: "You have joined this scene."
  end

  sig { returns(T.nilable(String)) }
  def join_blocker
    return "Cannot join a private scene." if scene.private? && !policy(scene).visible?
    return "Cannot join a resolved scene." if scene.resolved?

    nil
  end

  sig { returns(T::Array[ScenePlayerPresenter]) }
  def players_with_characters
    characters_by_user = game.characters.active
      .joins("INNER JOIN game_members ON game_members.user_id = characters.user_id AND game_members.game_id = #{game.id}")
      .where(game_members: { role: "player", status: "active" })
      .order(:name)
      .group_by(&:user_id)

    active_players.map { |user| ScenePlayerPresenter.new(user, characters: characters_by_user.fetch(user.id, [])) }
  end

  sig { returns(T.untyped) }
  def active_players
    game.users.joins(:game_members)
      .where(game_members: { game: game, role: "player", status: "active" })
      .order("user_profiles.display_name")
      .joins("LEFT JOIN user_profiles ON user_profiles.user_id = users.id")
  end

  sig { returns(SceneParticipantRosterPresenter) }
  def current_character_ids_presenter
    selected_ids = scene.scene_participants.where.not(character_id: nil).pluck(:character_id)
    SceneParticipantRosterPresenter.new(selected_ids)
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(game)
  end
end
