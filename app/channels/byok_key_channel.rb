# typed: true

# Subscription authorization for the per-user BYOK keypair-ready stream.
#
# After "Set up encryption" enqueues KeypairGenerationJob, the Profile screen
# shows a pending spinner frame subscribed to `[current_user, :byok_keypair]`
# via `turbo_stream_from`, and the worker broadcasts the finished paste form to
# that stream once the keypair exists (KeypairReadyBroadcast). The stream name
# is cryptographically signed, so a client cannot invent one — but a signed name
# is still just a string the browser holds, so this channel additionally
# confirms the connected user is the owner the stream names: it recomputes the
# stream name THIS user would produce and accepts only if that equals the
# verified name. One user cannot subscribe to another's keypair stream.
class ByokKeyChannel < Turbo::StreamsChannel
  extend T::Sig

  # The Turbo Frame id the pending frame carries and the worker's completion
  # broadcast targets — one constant so the page render and the broadcast can
  # never disagree on which frame to replace.
  PENDING_FRAME_ID = "byok_keypair_pending"

  sig { void }
  def subscribed
    verified = verified_stream_name_from_params

    if verified.present? && verified == authorized_stream_name
      stream_from verified
    else
      reject
    end
  end

  private

  # The one (unsigned) stream name this connection's user is entitled to: their
  # own keypair stream. Compared against verified_stream_name_from_params, which
  # also returns the UNSIGNED name — so this must be unsigned too. Nil for an
  # unauthenticated socket, which then fails the equality check and is rejected.
  sig { returns(T.nilable(String)) }
  def authorized_stream_name
    user = current_user
    return nil unless user

    canonical_stream_name([ user, :byok_keypair ])
  end

  # The canonical UNSIGNED stream name for a streamable — obtained by signing
  # then verifying, since Turbo exposes the name-builder only through those two
  # class methods. Matches verified_stream_name_from_params' form, so the two
  # are directly comparable.
  sig { params(streamables: T::Array[T.untyped]).returns(String) }
  def canonical_stream_name(streamables)
    Turbo::StreamsChannel.verified_stream_name(Turbo::StreamsChannel.signed_stream_name(streamables))
  end

  # The connected viewer, identified by ApplicationCable::Connection's
  # `identified_by :current_user`. Action Cable delegates that identifier to
  # each channel, but the delegation is invisible to Sorbet — declare it so this
  # channel's authorization logic stays typed. Nil for an unauthenticated socket.
  sig { returns(T.nilable(User)) }
  def current_user
    connection.current_user
  end
end
