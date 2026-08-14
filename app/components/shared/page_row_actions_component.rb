# typed: strict

# The GM's per-row actions on the Pages list: edit the page, or delete it
# behind a confirmation. Rendered as a Shared::ListEntryComponent row's
# controls, so the list itself stays unaware of what a page row can do.
class Shared::PageRowActionsComponent < ApplicationComponent
  extend T::Sig

  CONFIRM = T.let("Delete this page? This cannot be undone.", String)

  sig { params(page: PagePresenter).void }
  def initialize(page:)
    @page = T.let(page, PagePresenter)
  end

  sig { returns(Game) }
  def game
    @page.game
  end

  sig { returns(PagePresenter) }
  attr_reader :page

  sig { returns(String) }
  def confirm
    CONFIRM
  end
end
