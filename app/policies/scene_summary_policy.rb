# typed: true
# frozen_string_literal: true

class SceneSummaryPolicy < ApplicationPolicy
  extend T::Sig

  # Only the GM writes, edits, or deletes a scene summary. The index is a plain
  # authenticated read authorized through GamePolicy#show? (authorize @game,
  # :show?) in the controller. new? => create?, edit? => update? via base.
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
