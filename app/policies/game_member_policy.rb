# typed: true
# frozen_string_literal: true

class GameMemberPolicy < ApplicationPolicy
  extend T::Sig

  # Only the GM changes a member's status, and the GM's own membership is not
  # modifiable (you cannot change GM status). The "invalid status" case is input
  # validation, enforced at the controller.
  sig { returns(T::Boolean) }
  def update?
    manager? && !record.game_master?
  end

  private

  sig { returns(T::Boolean) }
  def manager?
    record.game.game_master?(user)
  end
end
