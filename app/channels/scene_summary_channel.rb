# typed: true

# Subscription authorization for the per-viewer scene-summary streams.
#
# The scene page subscribes each viewer to `[scene, :summary, <visibility_class>]`
# via `turbo_stream_from`, and SceneSummaryJob broadcasts a finished summary only
# to the classes entitled to see it (SceneSummaryVisibility). The stream name is
# cryptographically signed, so a client cannot invent a stream — but a signed
# name is still just a string the browser holds, so this channel additionally
# confirms the connected user is actually entitled to the class they ask for:
# it recomputes the stream name THIS user's own visibility class would produce
# for the requested scene and accepts only if that equals the verified name. A
# `plain` viewer replaying a `manager` stream name is rejected.
class SceneSummaryChannel < Turbo::StreamsChannel
  extend T::Sig

  # The Turbo Frame id the pending scene-summary frame carries and the worker's
  # completion broadcast targets — one constant so the page render and the
  # broadcast can never disagree on which frame to replace.
  PENDING_FRAME_ID = "scene_summary_pending"

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
  # requested scene: their own visibility class. Compared against
  # verified_stream_name_from_params, which also returns the UNSIGNED name — so
  # this must be unsigned too, not signed_stream_name. Nil if the scene is
  # missing or the user cannot view the game at all — either way no authorized
  # name, so any verified name fails the equality check and the subscription is
  # rejected.
  sig { returns(T.nilable(String)) }
  def authorized_stream_name
    scene = Scene.find_by(id: params[:scene_id])
    game = scene&.game
    return nil unless game && GamePolicy.new(current_user, game).view?

    klass = SceneSummaryVisibility.for_viewer(game: game, viewer: current_user)
    canonical_stream_name([ scene, :summary, klass ])
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
