# typed: strict

# The "Sheet visibility" settings row on the Edit Game screen: a text-link
# control that flips whether character sheets are hidden from players. Owns
# the full row (label, sub-label, toggle link) — same pattern as
# Shared::ImagesToggleComponent / Shared::AiSummariesToggleComponent.
class Shared::SheetsToggleComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter).void }
  def initialize(game:)
    @game = T.let(game, GamePresenter)
  end

  sig { returns(T::Boolean) }
  def hidden?
    @game.sheets_hidden?
  end

  sig { returns(String) }
  def toggle_label
    hidden? ? "Show Character Sheets" : "Hide Character Sheets"
  end

  sig { returns(String) }
  # mutant:disable
  def toggle_path
    T.unsafe(helpers).toggle_sheets_hidden_game_path(@game)
  end
end
