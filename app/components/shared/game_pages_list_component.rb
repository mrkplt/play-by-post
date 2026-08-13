# typed: strict

# The Pages tab panel on the Game View: a list of the game's pages (title →
# page), newest interface with the GM's "New Page" action pinned above. Renders
# inside the client-side tab switcher in games#show, so it is the in-page index
# of pages — every non-banned member sees it; only the GM sees "New Page".
#
# The row layout itself lives in Shared::ListEntryComponent, shared with the
# Notebook lanes; this component decides only what a page row links to and
# which controls it carries.
class Shared::GamePagesListComponent < ApplicationComponent
  extend T::Sig

  EMPTY_TEXT = T.let("No pages yet.", String)

  sig { params(game: Game, pages: T::Array[Page], is_gm: T::Boolean).void }
  def initialize(game:, pages:, is_gm:)
    @game = game
    @pages = pages
    @is_gm = is_gm
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(T::Array[Page]) }
  attr_reader :pages

  sig { returns(T::Boolean) }
  def gm?
    @is_gm
  end

  sig { returns(String) }
  def empty_text
    EMPTY_TEXT
  end

  sig { returns(T::Array[Shared::ListEntryComponent::Row]) }
  def rows
    pages.map { |page| row_for(page) }
  end

  sig { params(page: Page).returns(Shared::ListEntryComponent::Row) }
  def row_for(page)
    {
      title: page.title.to_s,
      href: helpers.game_page_path(game, page),
      controls: row_controls(page)
    }
  end

  # Only the GM can act on a page, so a player's rows carry no controls at all.
  sig { params(page: Page).returns(T.nilable(ViewComponent::Base)) }
  def row_controls(page)
    return nil unless gm?

    Shared::PageRowActionsComponent.new(game: game, page: page)
  end
end
