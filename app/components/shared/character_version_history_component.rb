# typed: strict

# The collapsible version-history table on a character sheet: one row per
# snapshot linking to the historical version, with the editor's name. Kept as a
# component so its table styling lives out of the view template.
class Shared::CharacterVersionHistoryComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      game: Game,
      character: Character,
      versions: T::Array[CharacterVersion],
      editor_names: T::Hash[Integer, String]
    ).void
  end
  def initialize(game:, character:, versions:, editor_names:)
    @game = T.let(game, Game)
    @character = T.let(character, Character)
    @versions = T.let(versions, T::Array[CharacterVersion])
    @editor_names = T.let(editor_names, T::Hash[Integer, String])
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(Character) }
  attr_reader :character

  sig { returns(T::Array[CharacterVersion]) }
  attr_reader :versions

  sig { returns(Integer) }
  def version_count
    @versions.size
  end

  sig { params(version: CharacterVersion).returns(T.nilable(String)) }
  def editor_name(version)
    @editor_names[version.id]
  end
end
