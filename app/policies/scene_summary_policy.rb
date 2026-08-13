# typed: true
# frozen_string_literal: true

class SceneSummaryPolicy < ApplicationPolicy
  extend T::Sig

  # Only the GM writes, edits, or deletes a scene summary. The index (a
  # members-only listing) is gated by require_game_access! at the controller.
  # new? => create?, edit? => update? via base.
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
    record.scene.game.game_master?(user)
  end
end
