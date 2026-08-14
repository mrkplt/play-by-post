# typed: strict

# The collapsible version-history table on a character sheet: one row per
# snapshot linking to the historical version, with the editor's name. Kept as a
# component so its table styling lives out of the view template.
class Shared::CharacterVersionHistoryComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      game: GamePresenter,
      character: CharacterPresenter,
      versions: T::Array[CharacterVersionPresenter]
    ).void
  end
  def initialize(game:, character:, versions:)
    @game = T.let(game, GamePresenter)
    @character = T.let(character, CharacterPresenter)
    @versions = T.let(versions, T::Array[CharacterVersionPresenter])
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(CharacterPresenter) }
  attr_reader :character

  sig { returns(T::Array[CharacterVersionPresenter]) }
  attr_reader :versions

  sig { returns(Integer) }
  def version_count
    @versions.size
  end
end
