# typed: true
# frozen_string_literal: true

class CharacterVersionPolicy < ApplicationPolicy
  extend T::Sig

  # Viewing a character version requires access to the game. (Version history
  # follows game access, not the per-sheet hidden gate.)
  sig { returns(T::Boolean) }
  def show?
    record.character.game.viewable_by?(user)
  end
end
