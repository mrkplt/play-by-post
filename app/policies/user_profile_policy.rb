# typed: true
# frozen_string_literal: true

class UserProfilePolicy < ApplicationPolicy
  extend T::Sig

  # A profile is only ever the current user's own — the owner rule guards against
  # a future param'd id turning this into someone else's profile. edit? =>
  # update? via base.
  sig { returns(T::Boolean) }
  def show?
    owner?
  end

  sig { returns(T::Boolean) }
  def update?
    owner?
  end

  # Hide-OOC and personal exports both act on the owner's own data.
  sig { returns(T::Boolean) }
  def manage?
    owner?
  end

  private

  sig { returns(T::Boolean) }
  def owner?
    record.user == user
  end
end
