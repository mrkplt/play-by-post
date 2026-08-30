# typed: strict

# The "AI Scene Summaries" toggle, rendered in two places that must share one
# DOM id (Shared::GameFlagToggle#wrapper_id) because
# Games::SettingsController#ai_summaries_enabled answers every flip with a
# single turbo_stream.replace targeting that id — whichever screen is on
# screen when the flip happens must have an element with that id, or the
# stream swap is a no-op and the switch never visibly moves (Fizzy #126).
#
# The two call sites want different presentations of the same control, so the
# presentation is parameterized rather than forked into a second component
# (per "parameterize variations" in docs/COMPONENT_CONVENTIONS.md):
# - :card (Edit Game) — an explanatory card with a text button.
# - :row (Player Management) — a Ui::SettingsRowComponent row with a
#   Ui::ToggleSwitchComponent, matching the other rows on that screen.
#
# Shares the label-flip logic with Shared::SheetsToggleComponent through
# Shared::GameFlagToggle; the route is its own.
class Shared::AiSummariesToggleComponent < ApplicationComponent
  extend T::Sig
  include Shared::GameFlagToggle

  PRESENTATIONS = T.let(%i[card row].freeze, T::Array[Symbol])

  sig { params(game: GamePresenter, presentation: Symbol).void }
  def initialize(game:, presentation: :card)
    raise ArgumentError, "Unknown presentation: #{presentation}" unless PRESENTATIONS.include?(presentation)

    @game = T.let(game, GamePresenter)
    @presentation = presentation
  end

  sig { returns(T::Boolean) }
  def row?
    @presentation == :row
  end

  sig { returns(Symbol) }
  def toggle_switch_state
    on? ? :on : :off
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

  sig { override.returns(String) }
  def flag_name
    "ai_summaries"
  end

  # The flip route, carrying the presentation so the controller renders the
  # same presentation back after the flip — the row's button must still be a
  # row (and the card's a card) after the in-place swap.
  sig { returns(String) }
  # mutant:disable
  def toggle_path
    T.unsafe(helpers).toggle_ai_summaries_enabled_game_path(@game, presentation: @presentation)
  end
end
