# typed: true
# frozen_string_literal: true

# Pages are readable by every non-banned member of the game (GM, active, or
# removed player) and writable only by the GM. new? => create? and
# edit? => update? via the base policy.
class PagePolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def show?
    viewable?
  end

  # May manage this game's pages: create, edit, and delete. Currently
  # answered by "is the GM" (gm? is the private implementation), but the
  # capability is the stable name — every CRUD predicate below delegates to
  # it, so when the rule granularizes this is the only line that changes.
  sig { returns(T::Boolean) }
  def manage?
    gm?
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

  sig { returns(T::Boolean) }
  def gm?
    record.game.game_master?(user)
  end

  sig { returns(T::Boolean) }
  def viewable?
    record.game.viewable_by?(user)
  end
end
