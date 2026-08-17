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

  # May this token drive the data API: it must be api-scoped AND its user must be
  # an active (non-banned, non-removed) member of the token's game — re-checked
  # every request, so lost membership disables the API even while the token
  # exists. Per-resource authorization (pages vs the GM-only notebook) is decided
  # by PagePolicy / NotebookEntryPolicy in the API controllers, not here.
  sig { returns(T::Boolean) }
  def api?
    return false unless record.scope == "api"

    GamePolicy.new(user, record.game).write_access?
  end
end
