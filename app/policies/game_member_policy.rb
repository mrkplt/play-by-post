# typed: true
# frozen_string_literal: true

class GameMemberPolicy < ApplicationPolicy
  extend T::Sig

  # May administer this game's roster: change a member's status. Answered by
  # "is the GM" (manager? is the private implementation) — the capability is
  # the stable name callers use, independent of who currently satisfies it.
  sig { returns(T::Boolean) }
  def manage?
    manager?
  end

  # Only the GM changes a member's status, and the GM's own membership is not
  # modifiable (you cannot change GM status) — two distinct questions: whether
  # the acting user holds the capability, and whether the target record is
  # eligible at all. Both must hold for the action to proceed. The "invalid
  # status" case is input validation, enforced at the controller.
  sig { returns(T::Boolean) }
  def update?
    manage? && target_eligible?
  end

  private

  sig { returns(T::Boolean) }
  def manager?
    record.game.game_master?(user)
  end

  # The GM's own membership status may never be changed, by anyone.
  sig { returns(T::Boolean) }
  def target_eligible?
    !record.game_master?
  end
end
