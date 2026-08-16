# typed: strict

# The collapsible version-history table on a notebook entry's edit screen: one
# row per snapshot linking to the historical version, with the editor's name.
# Mirrors Shared::PageVersionHistoryComponent — kept as a component so its table
# styling lives out of the view template.
class Shared::NotebookEntryVersionHistoryComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      game: GamePresenter,
      entry: NotebookEntryPresenter,
      versions: T::Array[NotebookEntryVersionPresenter]
    ).void
  end
  def initialize(game:, entry:, versions:)
    @game = T.let(game, GamePresenter)
    @entry = T.let(entry, NotebookEntryPresenter)
    @versions = T.let(versions, T::Array[NotebookEntryVersionPresenter])
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(NotebookEntryPresenter) }
  attr_reader :entry

  sig { returns(T::Array[NotebookEntryVersionPresenter]) }
  attr_reader :versions

  # The rows for the shared Shared::VersionHistoryComponent — each version's own
  # URL plus the table values.
  sig { returns(T::Array[Shared::VersionHistoryComponent::Row]) }
  def rows
    versions.map do |version|
      Shared::VersionHistoryComponent::Row.new(
        path: helpers.game_notebook_entry_notebook_entry_version_path(game, entry, version),
        timestamp: version.created_at_timestamp,
        formatted: version.formatted_created_at,
        editor: version.editor_name
      )
    end
  end
end
