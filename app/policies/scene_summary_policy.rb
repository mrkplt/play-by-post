# typed: true
# frozen_string_literal: true

class SceneSummaryPolicy < ApplicationPolicy
  extend T::Sig

  # Only the GM writes, edits, or deletes a scene summary. The index (a
  # members-only listing) is gated by require_game_access! at the controller.
  # new? => create?, edit? => update? via base.

  # May write, edit, or delete this scene's summary. Currently answered by
  # "is the GM" (gm? is the private implementation); every write predicate
  # below delegates to it so a rule change is a one-line edit.
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

  # May publish a draft summary, making it visible in the members log and the
  # RSS feed — the same GM capability as managing it, named for the publish
  # action rather than borrowing a CRUD predicate.
  sig { returns(T::Boolean) }
  def publish?
    manage?
  end

  private

  sig { returns(T::Boolean) }
  def gm?
    record.scene.game.game_master?(user)
  end
end
