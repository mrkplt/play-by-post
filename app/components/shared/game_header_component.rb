# typed: strict

# The dark game-scoped header for the Game View: a hamburger (opens the nav
# drawer), an optional GM crown, the game title, an optional trailing gear
# (Game Settings, shown to any viewer with game access), and a row of pill
# tabs that switch in-page panels (Scenes / Roster / Files) client-side — no
# cross-page navigation.
#
# Composed entirely from Ui primitives.
class Shared::GameHeaderComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      game: Game,
      title: String,
      is_gm: T::Boolean,
      active_tab: Symbol,
      show_gear: T::Boolean
    ).void
  end
  def initialize(game:, title:, is_gm: false, active_tab: :scenes, show_gear: true)
    @game = game
    @title = title
    @is_gm = is_gm
    @active_tab = active_tab
    @show_gear = show_gear
  end

  sig { returns(String) }
  attr_reader :title

  # The crown renders only when the viewer is the GM of this game (never
  # hardcoded — driven by is_gm).
  sig { returns(T::Boolean) }
  def show_crown?
    @is_gm
  end

  # The gear (Game Settings) is shown to every viewer who reached this page
  # — GM, active player, or removed player — since the settings page itself
  # scopes GM-only content internally.
  sig { returns(T::Boolean) }
  def show_gear?
    @show_gear
  end

  sig { returns(String) }
  def gear_path
    T.unsafe(helpers).game_player_management_path(@game)
  end

  sig { returns(Symbol) }
  attr_reader :active_tab

  sig { returns(T::Array[Ui::PillTabsComponent::Tab]) }
  def tabs
    [
      Ui::PillTabsComponent::Tab.new(label: "Scenes", panel: :scenes),
      Ui::PillTabsComponent::Tab.new(label: "Roster", panel: :roster),
      Ui::PillTabsComponent::Tab.new(label: "Files", panel: :files)
    ]
  end
end
