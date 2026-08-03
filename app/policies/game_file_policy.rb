# typed: true
# frozen_string_literal: true

class GameFilePolicy < ApplicationPolicy
  extend T::Sig

  # Only the GM uploads or deletes files. new? => create? via base.
  sig { returns(T::Boolean) }
  def create?
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
