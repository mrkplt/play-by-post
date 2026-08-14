# typed: true

class CharacterVersionsController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  before_action :set_character
  before_action :set_version
  after_action :verify_authorized

  sig { void }
  def show
    authorize @version
    @editor = UserPresenter.new(@version.edited_by)
    @character_presenter = CharacterPresenter.new(@character, game_policy: policy(@game))
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def set_character
    @character = @game.characters.find(params[:character_id])
  end

  sig { void }
  def set_version
    @version = @character.character_versions.find(params[:id])
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end
end
