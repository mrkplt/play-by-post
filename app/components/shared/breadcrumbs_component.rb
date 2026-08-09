# typed: strict

# Single-level breadcrumb rendered inside Shared::HeaderComponent's
# breadcrumbs slot: a single link back to the owning game's page. Distinct
# from the general-purpose Ui::BreadcrumbComponent (an unstyled content
# wrapper for light-page multi-level trails) — this is dark-header-styled
# and game-specific by design, since a game is the only "back" context an
# in-game screen needs today.
class Shared::BreadcrumbsComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game).void }
  def initialize(game:)
    @game = game
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(String) }
  def game_href
    T.unsafe(helpers).game_path(@game)
  end

  sig { returns(String) }
  def game_name
    T.unsafe(@game).name
  end
end
