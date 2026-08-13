# typed: true
# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  extend T::Sig

  # May send, cancel, or resend this game's invitations. Currently answered
  # by "is the GM" (gm? is the private implementation); every predicate below
  # delegates to it so a rule change is a one-line edit. new? => create? via
  # base.
  sig { returns(T::Boolean) }
  def manage?
    gm?
  end

  sig { returns(T::Boolean) }
  def create?
    manage?
  end

  sig { returns(T::Boolean) }
  def destroy?
    manage?
  end

  sig { returns(T::Boolean) }
  def resend?
    manage?
  end

  private

  sig { returns(T::Boolean) }
  def gm?
    record.game.game_master?(user)
  end
end
