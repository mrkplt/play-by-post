# typed: strict
# frozen_string_literal: true

# Builds the GamePresenter/CharacterPresenter pair CharactersController's
# read and error-path renders need. Only the controller has Pundit's
# `policy(...)` to hand over already resolved (presenters never construct
# authorization), so this takes both policies rather than building them.
class CharacterPresenterBuilder
  extend T::Sig

  sig { params(game: Game, game_policy: GamePolicy).void }
  def initialize(game, game_policy)
    @game = game
    @game_policy = game_policy
  end

  sig { returns(GamePresenter) }
  def game_presenter
    GamePresenter.new(@game, policy: @game_policy)
  end

  sig { params(character: Character, character_policy: CharacterPolicy).returns(CharacterPresenter) }
  def character_presenter(character, character_policy)
    CharacterPresenter.new(
      character, game_policy: @game_policy, character_policy: character_policy, players: players_for_select
    )
  end

  sig { params(character: Character).returns(T::Array[CharacterVersionPresenter]) }
  def versions(character)
    character.character_versions.order(created_at: :desc).includes(:edited_by)
      .map { |version| CharacterVersionPresenter.new(version) }
  end

  private

  sig { returns(T::Array[User]) }
  def players_for_select
    @game.active_members.where(role: "player").includes(:user).map(&:user)
  end
end
