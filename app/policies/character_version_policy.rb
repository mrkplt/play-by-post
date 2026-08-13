# typed: true
# frozen_string_literal: true

class CharacterVersionPolicy < ApplicationPolicy
  extend T::Sig

  # Viewing a character version requires access to the game. (Version history
  # follows game access, not the per-sheet hidden gate.) Routed through
  # GamePolicy#view? rather than reaching through two associations directly,
  # so the game-access rule has one implementation.
  sig { returns(T::Boolean) }
  def show?
    GamePolicy.new(user, record.character.game).view?
  end
end
