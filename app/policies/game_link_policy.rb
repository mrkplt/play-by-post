# typed: true
# frozen_string_literal: true

# Game links are readable by every non-banned member of the game (GM, active,
# or removed player) and writable only by the GM. new? => create? and
# edit? => update? via the base policy.
class GameLinkPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def index?
    viewable?
  end

  sig { returns(T::Boolean) }
  def create?
    gm?
  end

  sig { returns(T::Boolean) }
  def update?
    gm?
  end

  sig { returns(T::Boolean) }
  def destroy?
    gm?
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
