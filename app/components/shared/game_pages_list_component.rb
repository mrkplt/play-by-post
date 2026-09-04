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

  sig { params(game: GamePresenter, pages: T::Array[PagePresenter], can_contribute: T::Boolean).void }
  def initialize(game:, pages:, can_contribute:)
    @game = game
    @pages = pages
    @can_contribute = can_contribute
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(T::Array[PagePresenter]) }
  attr_reader :pages

  # Whether to show the "New Page" affordance: the GM or a contributing player
  # (Fizzy #18). Per-row Edit/Delete are decided per page, not by this flag.
  sig { returns(T::Boolean) }
  def can_contribute?
    @can_contribute
  end

  sig { returns(String) }
  def empty_text
    EMPTY_TEXT
  end

  sig { returns(T::Array[Shared::ListEntryComponent::Row]) }
  def rows
    pages.map { |page| row_for(page) }
  end

  sig { params(page: PagePresenter).returns(Shared::ListEntryComponent::Row) }
  def row_for(page)
    page.list_row_attributes.merge(controls: row_controls(page))
  end

  # A row carries controls when the viewer may act on THAT page — edit (GM) or
  # delete (GM or the page's own author, Fizzy #18). The row component self-gates
  # each button, so it is rendered whenever any action is available and omitted
  # entirely otherwise. PageRowActionsComponent takes a PagePresenter, and this
  # list already holds presenters — so the row passes straight through.
  sig { params(page: PagePresenter).returns(T.nilable(ViewComponent::Base)) }
  def row_controls(page)
    actions = page.actions
    return nil unless actions.can_edit? || actions.can_delete?

    Shared::PageRowActionsComponent.new(page: page)
  end
end
