# typed: strict

# The collapsible version-history table on a character sheet: one row per
# snapshot linking to the historical version, with the editor's name. Kept as a
# component so its table styling lives out of the view template.
#
# Takes the character (for the row link's route args) and an array of
# CharacterVersionPresenter — each version presenter exposes its own
# `editor_name`, so this component no longer needs a separate lookup hash
# keyed by version id alongside the array of versions.
class Shared::CharacterVersionHistoryComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      character: CharacterPresenter,
      versions: T::Array[CharacterVersionPresenter]
    ).void
  end
  def initialize(character:, versions:)
    @character = T.let(character, CharacterPresenter)
    @versions = T.let(versions, T::Array[CharacterVersionPresenter])
  end

  sig { returns(Game) }
  def game
    character.game
  end

  sig { returns(CharacterPresenter) }
  attr_reader :character

  sig { returns(T::Array[CharacterVersionPresenter]) }
  attr_reader :versions

  # The rows for the shared Shared::VersionHistoryComponent — each version's own
  # URL plus the table values.
  sig { returns(T::Array[Shared::VersionHistoryComponent::Row]) }
  def rows
    versions.map do |version|
      Shared::VersionHistoryComponent::Row.new(
        path: helpers.game_character_character_version_path(game, character, version),
        timestamp: version.created_at_timestamp,
        formatted: version.formatted_created_at,
        editor: version.editor_name
      )
    end
  end
end
