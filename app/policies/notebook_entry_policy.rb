# typed: true
# frozen_string_literal: true

# Notebook entries are GM-only in every direction — unlike Page/GameLink, no
# other member can view or write them. new? => create? and edit? => update?
# via the base policy.
class NotebookEntryPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def index?
    gm?
  end

  # Stated for the resource, not for a route: no screen reads a single entry
  # today, but "a notebook entry is never readable by a non-GM" is the rule
  # this policy exists to declare, and it must not depend on which actions
  # happen to be routed.
  sig { returns(T::Boolean) }
  def show?
    gm?
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

  # Working the notebook itself: moving an entry between lanes, promoting it to
  # a Page. Named for the game function rather than borrowing `update?` — that
  # asks whether the record may be edited, which is a different question with
  # the same answer only while the GM is also the game's owner. When that
  # splits, this line changes and no caller does.
  sig { returns(T::Boolean) }
  def manage?
    gm?
  end

  private

  sig { returns(T::Boolean) }
  def gm?
    record.game.game_master?(user)
  end
end
