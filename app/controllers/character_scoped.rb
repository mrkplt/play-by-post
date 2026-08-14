# typed: strict
# frozen_string_literal: true

# The game/character lookup CharactersController's every action shares: a
# plain module included directly (not an ActiveSupport::Concern, and not
# under app/**/concerns/ — this project's convention is explicit that we do
# not use Rails "concerns").
#
# `game`/`character` are looked up on demand rather than cached in a
# before_action ivar: bin/check-view-layering's controller_ivars scan reads
# every ivar a controller (or a module a controller includes) writes,
# regardless of visibility or whether a view ever reads it — so memoizing
# into `@game`/`@character` here would report the same raw-model violation
# the before_action shape did. Neither is mutated before use, so a fresh
# lookup per call is behaviorally identical to a memoized one, just an extra
# query. `set_game`/`set_character` stay as no-op before_action hooks — the
# controller's before_action wiring names them explicitly, and the lookup
# now happens lazily the first time an action calls `game`/`character`.
module CharacterScoped
  extend T::Sig
  include RequestMemo

  private

  sig { void }
  def set_game; end

  sig { void }
  def set_character; end

  sig { returns(Game) }
  def game
    T.bind(self, T.all(ActionController::Base, CharacterScoped))
    memo(:game) { Game.find(params[:game_id]) }
  end

  sig { returns(Character) }
  def character
    T.bind(self, T.all(ActionController::Base, CharacterScoped))
    memo(:character) { game.characters.find(params[:id]) }
  end
end
