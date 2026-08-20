# typed: strict

# The "Sheet visibility" settings row on the Edit Game screen: a text-link
# control that flips whether character sheets are hidden from players. Owns
# the full row (label, sub-label, toggle link) — same pattern as
# Shared::AiSummariesToggleComponent, which shares the label-flip logic through
# Shared::GameFlagToggle.
class Shared::SheetsToggleComponent < ApplicationComponent
  extend T::Sig
  include Shared::GameFlagToggle

  sig { params(game: GamePresenter).void }
  def initialize(game:)
    @game = T.let(game, GamePresenter)
  end

  sig { returns(T::Boolean) }
  def hidden?
    @game.sheets_hidden?
  end

  sig { override.returns(T::Boolean) }
  def on?
    hidden?
  end

  sig { override.returns(String) }
  def on_label
    "Show Character Sheets"
  end

  sig { override.returns(String) }
  def off_label
    "Hide Character Sheets"
  end

  sig { returns(String) }
  # mutant:disable
  def toggle_path
    T.unsafe(helpers).toggle_sheets_hidden_game_path(@game)
  end
end
