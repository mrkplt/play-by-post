# typed: strict

# Single-level breadcrumb rendered inside Shared::HeaderComponent's
# breadcrumbs slot: a single link back to the owning game's page. Distinct
# from the general-purpose Ui::BreadcrumbComponent (an unstyled content
# wrapper for light-page multi-level trails) — this is dark-header-styled
# and game-specific by design, since a game is the only "back" context an
# in-game screen needs today.
#
# Takes the game's presenter rather than the model: all this needs is the
# game's id (for routing) and name, both already exposed through the
# presenter every screen already builds.
class Shared::BreadcrumbsComponent < ApplicationComponent
  extend T::Sig

  sig { params(game_presenter: GamePresenter).void }
  def initialize(game_presenter:)
    @game_presenter = game_presenter
  end

  sig { returns(String) }
  def game_href
    T.unsafe(helpers).game_path(@game_presenter)
  end

  sig { returns(String) }
  def game_name
    T.unsafe(@game_presenter).name
  end
end
