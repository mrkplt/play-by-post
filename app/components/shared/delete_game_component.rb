# typed: strict

# The GM's "Danger Zone" delete control on the Game Settings page: a delete
# button plus a hidden confirmation modal that requires typing the game's exact
# name before the destructive submit is enabled. GM-only — the caller gates
# rendering on the GM check.
class Shared::DeleteGameComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter).void }
  # mutant:disable
  def initialize(game:)
    @game = T.let(game, GamePresenter)
  end

  sig { returns(String) }
  def game_name
    @game.name
  end

  sig { returns(String) }
  def delete_path
    helpers.game_path(@game)
  end

  sig { returns(String) }
  def confirm_instruction
    %(Type "#{game_name}" to confirm)
  end

  sig { returns(String) }
  def delete_heading
    %(Delete "#{game_name}"?)
  end
end
