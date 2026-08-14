# typed: strict

class CharacterVersionsController < ApplicationController
  extend T::Sig

  # The three route-nested records this controller resolves once per request
  # (game -> character -> version), found together by #set_records rather
  # than through three separate before_actions each writing their own ivar —
  # one lookup, one ivar, so the class stays under reek's instance-variable
  # ceiling without hiding the lookups behind ad hoc private methods.
  Records = Struct.new(:game, :character, :version)

  before_action :set_records
  before_action :require_game_access!
  after_action :verify_authorized

  sig { void }
  def show
    authorize version
    game_policy = policy(game)
    @version_presenter = T.let(CharacterVersionPresenter.new(version), T.nilable(CharacterVersionPresenter))
    @character_presenter = T.let(
      CharacterPresenter.new(character, game_policy: game_policy),
      T.nilable(CharacterPresenter)
    )
    @game_presenter = T.let(GamePresenter.new(game, policy: game_policy), T.nilable(GamePresenter))
  end

  private

  sig { void }
  def set_records
    game = Game.find(params[:game_id])
    character = game.characters.find(params[:character_id])
    version = character.character_versions.find(params[:id])
    @records = T.let(Records.new(game, character, version), T.nilable(Records))
  end

  sig { returns(Game) }
  def game
    T.must(@records).game
  end

  sig { returns(Character) }
  def character
    T.must(@records).character
  end

  sig { returns(CharacterVersion) }
  def version
    T.must(@records).version
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end
end
