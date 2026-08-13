# typed: strict

# The GM's per-row actions on the Pages list: edit the page, or delete it
# behind a confirmation. Rendered as a Shared::ListEntryComponent row's
# controls, so the list itself stays unaware of what a page row can do.
class Shared::PageRowActionsComponent < ApplicationComponent
  extend T::Sig

  CONFIRM = T.let("Delete this page? This cannot be undone.", String)

  sig { params(game: Game, page: Page).void }
  def initialize(game:, page:)
    @game = game
    @page = page
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(Page) }
  attr_reader :page

  sig { returns(String) }
  def confirm
    CONFIRM
  end
end
