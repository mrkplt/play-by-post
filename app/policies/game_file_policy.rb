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

  # The GM always may; an active player may when the GM has enabled player
  # contributions for the game (Fizzy #18). new? => create? via base.
  sig { returns(T::Boolean) }
  def create?
    manage? || player_contributor?
  end

  # The GM may delete any file; a contributing player may delete one they
  # uploaded while contributions are enabled (turning the setting off revokes
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
end
