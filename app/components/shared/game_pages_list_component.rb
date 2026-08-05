# typed: strict

# The Pages tab panel on the Game View: a list of the game's pages (title →
# page), newest interface with the GM's "New Page" action pinned above. Renders
# inside the client-side tab switcher in games#show, so it is the in-page index
# of pages — every non-banned member sees it; only the GM sees "New Page".
class Shared::GamePagesListComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, pages: T::Array[Page], is_gm: T::Boolean).void }
  def initialize(game:, pages:, is_gm:)
    @game = T.let(game, Game)
    @pages = T.let(pages, T::Array[Page])
    @is_gm = T.let(is_gm, T::Boolean)
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(T::Array[Page]) }
  attr_reader :pages

  sig { returns(T::Boolean) }
  def gm?
    @is_gm
  end

  sig { returns(T::Boolean) }
  def any_pages?
    @pages.any?
  end

  ROW_BASE = T.let("flex items-center gap-2 px-4 py-3 no-underline", String)

  # Every row but the first carries a top divider, so the list reads as a
  # single grouped card rather than separate cells.
  sig { params(index: Integer).returns(String) }
  def row_classes(index)
    return ROW_BASE if index.zero?

    "#{ROW_BASE} border-t border-card-divider"
  end
end
