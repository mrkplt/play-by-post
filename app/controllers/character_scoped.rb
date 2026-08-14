# typed: strict
# frozen_string_literal: true

# The game/character lookup CharactersController's every action shares: a
# plain module included directly (not an ActiveSupport::Concern, and not
# under app/**/concerns/ — this project's convention is explicit that we do
# not use Rails "concerns"), so the before_action wiring stays visible in the
# controller itself. `||=` rather than `=`: each request builds a fresh
# controller (so this still runs exactly once), and the memoized form is the
# only ivar-write shape this project's ivar-hygiene gate treats as
# initialization rather than mutation.
module CharacterScoped
  extend T::Sig

  private

  sig { void }
  def set_game
    T.bind(self, T.all(ActionController::Base, CharacterScoped))
    @game ||= T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_character
    T.bind(self, T.all(ActionController::Base, CharacterScoped))
    @character ||= T.let(game.characters.find(params[:id]), T.nilable(Character))
  end

  sig { returns(Game) }
  def game
    T.must(@game)
  end

  sig { returns(Character) }
  def character
    T.must(@character)
  end
end
