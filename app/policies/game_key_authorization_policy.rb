# typed: true
# frozen_string_literal: true

# Authorizes a person offering/revoking THEIR OWN key contribution to a game.
# Any member may contribute their key (consent is the key owner's), so the
# capability is role-neutral — it is not a GM function. Two facts must hold:
# the acting user is a member of the game, and the authorization being
# created/destroyed is the acting user's own (you cannot offer or revoke
# someone else's key).
class GameKeyAuthorizationPolicy < ApplicationPolicy
  extend T::Sig

  # May the acting user manage (offer/revoke) THIS authorization — i.e. is it
  # their own, on a game they belong to.
  sig { returns(T::Boolean) }
  def contribute?
    own_record? && member?
  end

  sig { returns(T::Boolean) }
  def create?
    contribute?
  end

  sig { returns(T::Boolean) }
  def destroy?
    contribute?
  end

  private

  sig { returns(T::Boolean) }
  def own_record?
    record.user_id == user.id
  end

  sig { returns(T::Boolean) }
  def member?
    record.game.game_members.exists?(user: user)
  end
end
