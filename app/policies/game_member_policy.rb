# typed: true
# frozen_string_literal: true

class GameMemberPolicy < ApplicationPolicy
  extend T::Sig

  # Only the GM changes a member's status. The "cannot change GM status" and
  # "invalid status" rules are business validation enforced at the controller.
  sig { returns(T::Boolean) }
  def update?
    record.game.game_master?(user)
  end
end
