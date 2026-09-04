# typed: strict

# The "Player Contributions" control on the Edit Game screen: a labelled card
# with a text button that flips whether active players may create pages, links,
# and files in this game (Fizzy #18). Owns its own card and section label so the
# edit view renders it as a single unit; shares the label-flip logic with the
# other game-flag toggles through Shared::GameFlagToggle.
#
# Rendered on one screen only (Edit Game), so — unlike the AI-summaries toggle —
# it is not parameterized by presentation. Games::SettingsController answers the
# flip with a turbo_stream.replace on #wrapper_id, so the card must carry that id.
class Shared::PlayerContributionsToggleComponent < ApplicationComponent
  extend T::Sig
  include Shared::GameFlagToggle

  sig { params(game: GamePresenter).void }
  def initialize(game:)
    @game = T.let(game, GamePresenter)
  end

  sig { returns(T::Boolean) }
  def enabled?
    @game.player_contributions_enabled?
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
    "Disable Player Contributions"
  end

  sig { override.returns(String) }
  def off_label
    "Enable Player Contributions"
  end

  sig { override.returns(String) }
  def flag_name
    "player_contributions"
  end

  sig { returns(String) }
  # mutant:disable
  def toggle_path
    T.unsafe(helpers).toggle_player_contributions_enabled_game_path(@game)
  end
end
