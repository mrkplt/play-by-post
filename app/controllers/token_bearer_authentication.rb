# typed: strict

# Controller mixin for endpoints authenticated by a per-request bearer token
# (e.g. the RSS feed's `?token=`) rather than a session. The token is resolved to
# an actor for THIS request only: the actor drives Pundit (`pundit_user`) so the
# endpoint authorizes through the normal policy objects, but nothing about the
# request is persisted.
#
# SECURITY INVARIANT — this is the whole point of the mixin. Including it and
# calling `authenticate_bearer!(actor)` authorizes the current request without
# ever establishing a session: no Devise `sign_in`, no `warden.set_user`, no
# session/cookie write, and `pundit_user` is kept separate from
# `Current.user`/`current_user` (which stay the session identity — nil for a
# token request). A guessed or brute-forced token therefore cannot be traded for
# an in-app session and used to impersonate the actor. Future per-request token
# endpoints should include this rather than re-deriving the guarantee, so the
# invariant lives (and is tested) in one place.
module TokenBearerAuthentication
  extend T::Sig

  # The actor authorized for this request, resolved from the bearer token. Not a
  # session — set fresh per request, never written back to Warden or Current.
  sig { params(actor: T.untyped).void }
  def authenticate_bearer!(actor)
    @bearer_actor = T.let(actor, T.untyped)
  end

  # Pundit authorizes as the token's bearer, not the (absent) session user.
  sig { returns(T.untyped) }
  def pundit_user
    @bearer_actor
  end
end
