# typed: strict
# frozen_string_literal: true

# Builds the GamePresenter/CharacterPresenter pair CharactersController's
# read and error-path renders need. Only the controller has Pundit's
# `policy(...)` to hand over already resolved (presenters never construct
# authorization), so this takes both policies rather than building them.
# `urls` (the constructing controller) is threaded onto CharacterPresenter so
# it can resolve its own show/edit/cancel hrefs — the templates never build a
# route themselves.
class CharacterPresenterBuilder
  extend T::Sig

  sig { params(game: Game, game_policy: GamePolicy, urls: T.untyped).void }
  def initialize(game, game_policy, urls:)
    @game = game
    @game_policy = game_policy
    @urls = urls
  end

  sig { returns(GamePresenter) }
  def game_presenter
    GamePresenter.new(@game, policy: @game_policy)
  end

  sig { params(character: Character, character_policy: CharacterPolicy).returns(CharacterPresenter) }
  def character_presenter(character, character_policy)
    CharacterPresenter.new(character, character_policy: character_policy, urls: @urls)
  end
end
