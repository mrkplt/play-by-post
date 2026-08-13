# typed: true
# frozen_string_literal: true

# Notebook entries are GM-only in every direction — unlike Page/GameLink, no
# other member can view or write them. new? => create? and edit? => update?
# via the base policy.
class NotebookEntryPolicy < ApplicationPolicy
  extend T::Sig

  # Working the notebook: reading the board, writing an entry, moving one
  # between lanes, promoting it to a Page. The notebook is a single GM
  # scratchpad, so one capability covers every direction — and every CRUD
  # predicate below delegates to it, so when the rule granularizes this is the
  # only line that changes.
  sig { returns(T::Boolean) }
  def manage?
    gm?
  end

  sig { returns(T::Boolean) }
  def index?
    manage?
  end

  # Stated for the resource, not for a route: no screen reads a single entry
  # today, but "a notebook entry is never readable by a non-GM" is the rule
  # this policy exists to declare, and it must not depend on which actions
  # happen to be routed.
  sig { returns(T::Boolean) }
  def show?
    manage?
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
end
