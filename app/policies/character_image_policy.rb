# typed: true
# frozen_string_literal: true

# A character's portrait library is managed only by the player who owns the
# character — deliberately narrower than the character sheet's own edit gate
# (which also lets the GM in). Portraits are the player's expression of their
# character, so the GM does not curate them. One capability — manage? — covers
# every direction (list, upload, set current, delete), and every CRUD predicate
# delegates to it, so when the rule granularizes this is the one line that
# changes.
class CharacterImagePolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def manage?
    owns_character?
  end

  sig { returns(T::Boolean) }
  def create?
    manage?
  end

  sig { returns(T::Boolean) }
  def update?
    manage?
  end

  sig { returns(T::Boolean) }
  def destroy?
    manage?
  end

  private

  # The acting user owns the image's character. A single chained predicate off
  # `record` so the symbolic verifier can encode it.
  sig { returns(T::Boolean) }
  def owns_character?
    record.character.user == user
  end
end
