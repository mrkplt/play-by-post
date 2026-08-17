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

  # Game master AND currently active: a banned (or removed) member never reads
  # or writes notes even if they still hold the game_master role. The role alone
  # is status-blind; the notebook is GM-only *in good standing*. Composed from
  # two single-call predicates so the symbolic verifier can encode each atom.
  sig { returns(T::Boolean) }
  def gm?
    game_master? && active?
  end

  sig { returns(T::Boolean) }
  def game_master?
    record.game.game_master?(user)
  end

  sig { returns(T::Boolean) }
  def active?
    record.game.active_member?(user)
  end
end
