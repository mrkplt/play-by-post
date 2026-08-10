# typed: strict

# The player -> character checkbox list shared by the New Scene form
# (Shared::SceneFormComponent) and the standalone Edit Participants page
# (scene_participants/edit). Each player row lists their active characters as
# checkboxes named "character_ids[]"; the GM is always included automatically
# server-side and is not shown here.
#
# `variant:` controls only the wrapper presentation:
#   :card   — the token-styled card wrapper used inside the New Scene form.
#   :simple — a lighter wrapper (no card border) for the standalone edit page.
class Shared::ParticipantCheckboxListComponent < ApplicationComponent
  extend T::Sig

  PlayerRow = T.type_alias { [ UserPresenter, T::Array[Character] ] }
  VARIANTS = T.let(%i[card simple].freeze, T::Array[Symbol])

  sig do
    params(
      players_with_characters: T::Array[PlayerRow],
      selected_character_ids: T::Array[String],
      variant: Symbol
    ).void
  end
  def initialize(players_with_characters:, selected_character_ids:, variant: :card)
    @players_with_characters = T.let(players_with_characters, T::Array[PlayerRow])
    @selected_character_ids = T.let(selected_character_ids, T::Array[String])
    @variant = T.let(variant, Symbol)
  end

  sig { returns(T::Array[PlayerRow]) }
  attr_reader :players_with_characters

  sig { returns(T::Boolean) }
  def card?
    @variant == :card
  end

  sig { returns(String) }
  def wrapper_classes
    card? ? "bg-card border border-card-border rounded-card px-3.5 py-1" : "flex flex-col gap-3"
  end

  sig { returns(String) }
  def row_classes
    card? ? "py-2 border-b border-card-divider last:border-b-0" : "flex flex-col gap-1"
  end

  sig { params(character: Character).returns(T::Boolean) }
  def character_checked?(character)
    @selected_character_ids.include?(character.id.to_s)
  end
end
