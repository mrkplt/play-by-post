# typed: strict

class Shared::AiSummariesToggleComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game).void }
  def initialize(game:)
    @game = T.let(game, Game)
  end

  sig { returns(T::Boolean) }
  def enabled?
    @game.ai_summaries_enabled?
  end

  sig { returns(String) }
  def status_text
    enabled? ? "enabled" : "disabled"
  end

  sig { returns(String) }
  def toggle_label
    enabled? ? "Disable AI Summaries" : "Enable AI Summaries"
  end

  sig { returns(String) }
  # mutant:disable
  def toggle_path
    T.unsafe(helpers).toggle_ai_summaries_enabled_game_path(@game)
  end
end
