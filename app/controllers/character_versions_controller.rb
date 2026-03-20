class CharacterVersionsController < ApplicationController
  before_action :set_game
  before_action :require_game_access!
  before_action :set_character
  before_action :set_version

  def show
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def set_character
    @character = @game.characters.find(params[:character_id])
  end

  def set_version
    @version = @character.character_versions.find(params[:id])
  end

  def require_game_access!
    membership = @game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to this game."
  end
end
