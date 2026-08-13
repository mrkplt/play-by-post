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
end
