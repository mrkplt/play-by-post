# typed: strict

# The Links tab panel on the Game View and the Links index page body: a red
# off-site warning banner at the top, then the game's links (description →
# the external URL, opened in a new tab), with GM-only New Link / Edit / Delete
# actions. Renders inside the client-side tab switcher in games#show, so it is
# the in-page index of links — every non-banned member sees it; only the GM
# manages links.
class Shared::GameLinksListComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter, game_links: T::Array[GameLinkPresenter], can_manage: T::Boolean).void }
  def initialize(game:, game_links:, can_manage:)
    @game = T.let(game, GamePresenter)
    @game_links = T.let(game_links, T::Array[GameLinkPresenter])
    @can_manage = T.let(can_manage, T::Boolean)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(T::Array[GameLinkPresenter]) }
  attr_reader :game_links

  sig { returns(T::Boolean) }
  def can_manage?
    @can_manage
  end

  sig { returns(T::Boolean) }
  def any_links?
    @game_links.any?
  end

  ROW_BASE = T.let("flex items-center gap-2 px-4 py-3", String)

  # Every row but the first carries a top divider, so the list reads as a
  # single grouped card rather than separate cells.
  sig { params(index: Integer).returns(String) }
  def row_classes(index)
    return ROW_BASE if index.zero?

    "#{ROW_BASE} border-t border-card-divider"
  end
end
