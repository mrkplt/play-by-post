# typed: strict

# A generic "the backend is still making this" surface. While a background job
# has not yet produced its result, this shows a spinner and a waiting message;
# when the job finishes it broadcasts the finished content over Action Cable and
# Turbo swaps it into this frame in place. State is nothing but presence on the
# page — reload or navigate away and the next viewer is treated identically;
# there is no per-user or per-initiator persistence.
#
# Mechanism: a Turbo Frame that subscribes to a signed Turbo Stream (via
# `turbo_stream_from`). The worker that runs the job broadcasts a
# `turbo_stream.replace` targeting this frame's id once the result exists, and
# every subscribed viewer's frame is replaced with the finished content. Because
# the stream name is signed and (for visibility-scoped content) authorized by a
# custom channel, a viewer only receives a broadcast meant for them.
#
# Not AI-specific. Scene summaries are the first consumer; the BYOK keypair job
# is the intended second. Callers supply: a stable `frame_id`, the `stream`
# streamable(s) to subscribe to, an optional `channel`/`stream_data` for an
# authorizing channel, and an optional waiting `message`.
class Shared::AsyncPendingComponent < ApplicationComponent
  extend T::Sig

  DEFAULT_MESSAGE = "Waiting…"

  # The Turbo Stream subscription: which streamable(s) to subscribe to, and the
  # optional authorizing channel + extra subscription params it needs.
  class Subscription < T::Struct
    const :stream, T.untyped
    const :channel, T.nilable(String)
    const :data, T::Hash[Symbol, T.untyped], default: {}

    extend T::Sig

    # The streamable(s) `turbo_stream_from` splats. An Array is passed through so
    # a caller can subscribe to `[record, :scope, class]`; a single streamable is
    # wrapped.
    sig { returns(T::Array[T.untyped]) }
    def streamables
      stream.is_a?(Array) ? stream : [ stream ]
    end

    # The `turbo_stream_from` options: the authorizing channel and any extra
    # subscription params the channel needs.
    sig { returns(T::Hash[Symbol, T.untyped]) }
    def options
      opts = T.let({}, T::Hash[Symbol, T.untyped])
      opts[:channel] = channel if channel
      opts[:data] = data if data.any?
      opts
    end
  end

  sig do
    params(
      frame_id: String,
      stream: T.untyped,
      channel: T.nilable(String),
      stream_data: T::Hash[Symbol, T.untyped],
      message: String
    ).void
  end
  def initialize(frame_id:, stream:, channel: nil, stream_data: {}, message: DEFAULT_MESSAGE)
    @frame_id = frame_id
    @subscription = T.let(Subscription.new(stream: stream, channel: channel, data: stream_data), Subscription)
    @message = message
  end

  sig { returns(String) }
  attr_reader :frame_id

  sig { returns(String) }
  attr_reader :message

  sig { returns(T::Array[T.untyped]) }
  def streamables
    @subscription.streamables
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def stream_options
    @subscription.options
  end
end
