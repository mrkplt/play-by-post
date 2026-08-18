# typed: true
# frozen_string_literal: true

# A user's avatar library is managed only by that user. One capability —
# manage? — covers every direction, and every CRUD predicate delegates to it.
class UserImagePolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def manage?
    own?
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

  # The image belongs to the acting user — the game function this policy states.
  sig { returns(T::Boolean) }
  def own?
    record.user == user
  end
end
