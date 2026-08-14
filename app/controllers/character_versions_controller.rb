# typed: strict

class CharacterVersionsController < ApplicationController
  extend T::Sig

  before_action :require_game_access!
  after_action :verify_authorized

  sig { void }
  def show
    authorize version
    @version_presenter = T.let(CharacterVersionPresenter.new(version), T.nilable(CharacterVersionPresenter))
    @character_presenter = T.let(CharacterPresenter.new(character), T.nilable(CharacterPresenter))
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
  end

  private

  # No before_action ivar: the three route-nested records (game -> character
  # -> version) are controller-internal plumbing only, never read by a
  # template, so under `# typed: strict` any ivar holding them (even a Struct)
  # would itself be a raw model reaching the view layer's boundary — Sorbet
  # requires a T.let on every ivar write under `strict`, and the gate reads
  # that declared type. Each accessor re-resolves from params on every call
  # rather than memoizing into an ivar; #show is the controller's only action,
  # so the handful of repeated single-row lookups this costs is not worth
  # reintroducing the ivar that caused the violation.
  sig { returns(Game) }
  def game
    Game.find(params[:game_id])
  end

  sig { returns(Character) }
  def character
    game.characters.find(params[:character_id])
  end

  sig { returns(CharacterVersion) }
  def version
    character.character_versions.find(params[:id])
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end
end
