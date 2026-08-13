# typed: true
# frozen_string_literal: true

class GameFilePolicy < ApplicationPolicy
  extend T::Sig

  # May upload or delete this game's files. Currently answered by "is the GM"
  # (gm? is the private implementation), but the capability is the stable
  # name — every CRUD predicate below delegates to it, so when the rule
  # granularizes this is the one line that changes.
  sig { returns(T::Boolean) }
  def manage?
    gm?
  end

  # new? => create? via base.
  sig { returns(T::Boolean) }
  def create?
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
end
