# typed: strict

class CharacterVersionsController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  before_action :set_character
  before_action :set_version
  after_action :verify_authorized

  sig { void }
  def show
    authorize version
    @version_presenter = T.let(CharacterVersionPresenter.new(version), T.nilable(CharacterVersionPresenter))
    @character_presenter = T.let(
      CharacterPresenter.new(character, game_policy: policy(game)),
      T.nilable(CharacterPresenter)
    )
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
  end

  private

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_character
    @character = T.let(game.characters.find(params[:character_id]), T.nilable(Character))
  end

  sig { void }
  def set_version
    @version = T.let(character.character_versions.find(params[:id]), T.nilable(CharacterVersion))
  end

  sig { returns(Game) }
  def game
    T.must(@game)
  end

  sig { returns(Character) }
  def character
    T.must(@character)
  end

  sig { returns(CharacterVersion) }
  def version
    T.must(@version)
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end
end
