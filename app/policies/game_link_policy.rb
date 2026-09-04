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

  # May add, edit, or remove this game's links. Currently answered by "is the
  # GM" (gm? is the private implementation); every write predicate below
  # delegates to it so a rule change is a one-line edit.
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

  # The GM may delete any link; a contributing player may delete one they
  # authored while contributions are enabled (turning the setting off revokes
  # delete-own, Fizzy #18).
  sig { returns(T::Boolean) }
  def destroy?
    manage? || (player_contributor? && record.created_by?(user))
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
