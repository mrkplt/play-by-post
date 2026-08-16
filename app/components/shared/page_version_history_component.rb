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

  # The rows for the shared Shared::VersionHistoryComponent — each version's own
  # URL plus the table values.
  sig { returns(T::Array[Shared::VersionHistoryComponent::Row]) }
  def rows
    versions.map do |version|
      Shared::VersionHistoryComponent::Row.new(
        path: helpers.game_page_page_version_path(game, page, version),
        timestamp: version.created_at_timestamp,
        formatted: version.formatted_created_at,
        editor: version.editor_name
      )
    end
  end
end
