# typed: true
# frozen_string_literal: true

# Pages are readable by every non-banned member of the game (GM, active, or
# removed player) and writable only by the GM. new? => create? and
# edit? => update? via the base policy.
class PagePolicy < ApplicationPolicy
  extend T::Sig

  # A published page is visible to every non-banned member; a draft is visible
  # only to a manager (the GM authoring it). Without the draft gate a player who
  # knows a draft page's slug could read unpublished content directly, bypassing
  # the list-level hiding in GameShowPresenter#visible_pages.
  sig { returns(T::Boolean) }
  def show?
    return manage? if record.draft?

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

  # May publish a draft page, making it visible to every member — the same GM
  # capability as managing it, named for the publish action so the affordance
  # and controller read as a capability rather than a borrowed CRUD predicate.
  sig { returns(T::Boolean) }
  def publish?
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
