class SceneParticipantsController < ApplicationController
  before_action :set_game
  before_action :set_scene
  before_action :require_gm_or_creator!

  def edit
    @all_participants = @game.users.joins(:game_members)
      .where(game_members: { game: @game, status: "active", role: "player" })
    @current_participant_ids = @scene.scene_participants.pluck(:user_id)
  end

  def update
    gm = @game.game_master
    user_ids = (Array(params[:participant_ids]).map(&:to_i) + [ gm.id ]).uniq

    @scene.scene_participants.where.not(user_id: user_ids).destroy_all
    user_ids.each { |uid| @scene.scene_participants.find_or_create_by!(user_id: uid) }

    redirect_to game_scene_path(@game, @scene), notice: "Participants updated."
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def set_scene
    @scene = @game.scenes.find(params[:scene_id])
  end

  def require_gm_or_creator!
    unless @game.game_master?(current_user) || @scene.participant?(current_user)
      redirect_to game_scene_path(@game, @scene), alert: "Not authorized."
    end
  end
end
