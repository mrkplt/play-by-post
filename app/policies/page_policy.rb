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

  # May list this game's pages at all (the /api index action). The list itself
  # is member-readable — same rule as a published page's #show — while draft
  # visibility within it stays gated per-record via #show?.
  sig { returns(T::Boolean) }
  def index?
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

  # The GM always may; an active player may when the GM has enabled player
  # contributions for the game (Fizzy #18).
  sig { returns(T::Boolean) }
  def create?
    manage? || player_contributor?
  end

  sig { returns(T::Boolean) }
  def update?
    manage?
  end

  # The GM may delete any page; a contributing player may delete one they
  # authored while contributions are enabled (turning the setting off revokes
  # delete-own, Fizzy #18).
  sig { returns(T::Boolean) }
  def destroy?
    manage? || (player_contributor? && record.created_by?(user))
  end

  # May publish a draft page, making it visible to every member — the same GM
  # capability as managing it, named for the publish action so the affordance
  # and controller read as a capability rather than a borrowed CRUD predicate.
  sig { returns(T::Boolean) }
  def publish?
    manage?
  end

  private

  # An active player in a game that has player contributions enabled. A GM asks
  # #manage? instead; this is the additive grant on top of it.
  sig { returns(T::Boolean) }
  def player_contributor?
    contributions_enabled? && active_member?
  end

  sig { returns(T::Boolean) }
  # mutant:disable — the `!!` only coerces the non-null boolean column's nilable
  # RBI type to a strict Boolean for Sorbet; dropping it cannot change behaviour
  # (the column is `null: false`, never nil at runtime).
  def contributions_enabled?
    !!record.game.player_contributions_enabled?
  end

  sig { returns(T::Boolean) }
  def active_member?
    record.game.active_member?(user)
  end

  sig { returns(T::Boolean) }
  def gm?
    record.game.game_master?(user)
  end

  sig { returns(T::Boolean) }
  def viewable?
    record.game.viewable_by?(user)
  end
end
