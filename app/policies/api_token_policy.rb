# typed: true
# frozen_string_literal: true

# Authorization for the machine-auth surface. The subject (`user`) is the token's
# own user (DataApplicationController#pundit_user), and the record is the
# ApiToken presented. A single question answers feed access: the token must be
# scoped for the feed AND its user must currently be an active member of the
# token's game — re-checked every request, so revoked membership kills the feed
# even while the token still exists.
class ApiTokenPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T::Boolean) }
  def feed?
    return false unless record.scope == "rss"

    GamePolicy.new(user, record.game).feed?
  end
end
