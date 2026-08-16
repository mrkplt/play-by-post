# typed: strict

# The collapsible version-history table on a page: one row per snapshot linking
# to the historical version, with the editor's name. Mirrors
# CharacterVersionHistoryComponent — kept as a component so its table styling
# lives out of the view template.
class Shared::PageVersionHistoryComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      page: PagePresenter,
      versions: T::Array[PageVersionPresenter]
    ).void
  end
  def initialize(page:, versions:)
    @page = T.let(page, PagePresenter)
    @versions = T.let(versions, T::Array[PageVersionPresenter])
  end

  sig { returns(Game) }
  def game
    page.game
  end

  sig { returns(PagePresenter) }
  attr_reader :page

  sig { returns(T::Array[PageVersionPresenter]) }
  attr_reader :versions

  sig { returns(Integer) }
  def version_count
    versions.size
  end
end
