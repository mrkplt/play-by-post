# typed: true
# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  extend T::Sig

  # Only the GM sends invitations. new? => create? via base.
  sig { returns(T::Boolean) }
  def create?
    gm?
  end

  # Only the GM cancels a pending invitation.
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
