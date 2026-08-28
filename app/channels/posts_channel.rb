# typed: true

# Subscription authorization for a scene's live post stream.
#
# The scene page subscribes every viewer to the single `[scene, :posts]` stream
# via `turbo_stream_from`, and PostBroadcast pushes new/edited posts to it when a
# post is created or updated. Unlike scene summaries, posts are not partitioned by
# visibility class — a post is shown to anyone who can see the scene (OOC hiding
# and the per-viewer edit affordance are handled client-side / by rendering the
# broadcast in a viewer-neutral form), so there is one stream per scene.
#
# The stream name is cryptographically signed, so a client cannot invent one —
# but a signed name is still just a string the browser holds, so this channel
# additionally confirms the connected user may actually view the scene (game
# access plus the private-scene gate, ScenePolicy#show?) before streaming. A
# non-member, or a non-participant of a private scene, is rejected.
class PostsChannel < Turbo::StreamsChannel
  extend T::Sig

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

  # The one (unsigned) stream name this connection's user is entitled to for the
  # requested scene, or nil when the scene is missing or the user cannot view it —
  # either way no authorized name, so any verified name fails the equality check
  # and the subscription is rejected. Unsigned to match
  # verified_stream_name_from_params' form.
  sig { returns(T.nilable(String)) }
  def authorized_stream_name
    scene = Scene.find_by(id: params[:scene_id])
    return nil unless scene && current_user && ScenePolicy.new(current_user, scene).show?

    canonical_stream_name([ scene, :posts ])
  end

  # The canonical UNSIGNED stream name for a streamable — obtained by signing then
  # verifying, since Turbo exposes the name-builder only through those two class
  # methods. Matches verified_stream_name_from_params' form, so the two are
  # directly comparable.
  sig { params(streamables: T::Array[T.untyped]).returns(String) }
  def canonical_stream_name(streamables)
    Turbo::StreamsChannel.verified_stream_name(Turbo::StreamsChannel.signed_stream_name(streamables))
  end

  # The connected viewer, identified by ApplicationCable::Connection's
  # `identified_by :current_user`. The delegation is invisible to Sorbet — declare
  # it so this channel's authorization logic stays typed. Nil for an
  # unauthenticated socket.
  sig { returns(T.nilable(User)) }
  def current_user
    connection.current_user
  end
end
