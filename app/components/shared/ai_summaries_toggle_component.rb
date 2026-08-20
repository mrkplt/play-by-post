# typed: strict

# The "AI Scene Summaries" card on the Edit Game screen: an explanatory card
# with a button that flips whether summaries are generated on scene resolution.
# Shares the label-flip logic with Shared::SheetsToggleComponent through
# Shared::GameFlagToggle; the presentation (a labelled card, not a settings row)
# and the route are its own.
class Shared::AiSummariesToggleComponent < ApplicationComponent
  extend T::Sig
  include Shared::GameFlagToggle

  sig { params(game: GamePresenter).void }
  def initialize(game:)
    @game = T.let(game, GamePresenter)
  end

  sig { returns(T::Boolean) }
  def enabled?
    @game.ai_summaries_enabled?
  end

  sig { returns(String) }
  def status_text
    enabled? ? "enabled" : "disabled"
  end

  sig { override.returns(T::Boolean) }
  def on?
    enabled?
  end

  sig { override.returns(String) }
  def on_label
    "Disable AI Summaries"
  end

  sig { override.returns(String) }
  def off_label
    "Enable AI Summaries"
  end

  sig { returns(String) }
  # mutant:disable
  def toggle_path
    T.unsafe(helpers).toggle_ai_summaries_enabled_game_path(@game)
  end
end
