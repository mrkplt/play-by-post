# typed: strict
# frozen_string_literal: true

# The game/character lookup CharactersController's every action shares: a
# plain module included directly (not an ActiveSupport::Concern, and not
# under app/**/concerns/ — this project's convention is explicit that we do
# not use Rails "concerns"). `requires_ancestor ApplicationController` lets
# Sorbet resolve the controller methods (params, and RequestMemo#memo)
# without a per-method T.bind.
#
# `game`/`character` are looked up on demand and memoized through RequestMemo
# rather than a `@game`/`@character` ivar: Rails copies controller ivars into
# the view, so those would be view-facing raw models the controller_ivars scan
# rejects. `set_game`/`set_character` stay as no-op before_action hooks — the
# controller's before_action wiring names them explicitly, and the lookup
# happens lazily the first time an action calls `game`/`character`.
module CharacterScoped
  extend T::Sig
  extend T::Helpers
  include RequestMemo

  requires_ancestor { ApplicationController }

  private

  sig { void }
  def set_game; end

  sig { void }
  def set_character; end

  sig { returns(Game) }
  def game
    memo(:game) { Game.find_by!(slug: params[:game_id]) }
  end

  sig { returns(Character) }
  def character
    memo(:character) { game.characters.find(params[:id]) }
  end
end
