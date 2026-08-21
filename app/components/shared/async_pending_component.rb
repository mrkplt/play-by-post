# typed: strict

# A generic "the backend is still making this" surface. While a background job
# has not yet produced its result, this shows a spinner and a waiting message
# and polls; once the result exists the same frame renders the finished content
# and stops polling. State is nothing but presence on the page — reload or
# navigate away and the next viewer is treated identically; there is no
# per-user or per-initiator persistence.
#
# Mechanism: a Turbo Frame driven by the `job-status` Stimulus controller, which
# re-fetches the poll path on an interval. The poll endpoint re-renders THIS
# component with `ready: false` (spinner, keeps the controller) until the row
# exists, then with `ready: true` and the finished content in the `ready` slot —
# the ready frame has no controller, so Stimulus tears the poller down on that
# swap. A completion toast, if wanted, is the consuming endpoint's job (it can
# ride a turbo_stream inside the ready frame); this component only shows the
# spinner and holds the poll wiring.
#
# Not AI-specific. Scene summaries are the first consumer; the BYOK keypair job
# is the intended second. Callers supply: a stable `frame_id`, the `poll_path`,
# the `ready?` fact, an optional waiting `message`, and — when ready — the
# content via the `ready` slot.
class Shared::AsyncPendingComponent < ApplicationComponent
  extend T::Sig

  renders_one :ready

  DEFAULT_MESSAGE = "Waiting…"

  # Where and how often the frame re-fetches while pending. One value so the
  # component holds a single poll concept rather than a path and an interval.
  class Poll < T::Struct
    const :path, String
    const :interval_ms, Integer, default: 3000
  end

  sig { params(frame_id: String, poll_path: String, ready: T::Boolean, message: String, interval_ms: Integer).void }
  def initialize(frame_id:, poll_path:, ready:, message: DEFAULT_MESSAGE, interval_ms: 3000)
    @frame_id = frame_id
    @ready = ready
    @message = message
    @poll = T.let(Poll.new(path: poll_path, interval_ms: interval_ms), Poll)
  end

  sig { returns(String) }
  attr_reader :frame_id

  sig { returns(String) }
  attr_reader :message

  sig { returns(T::Boolean) }
  def ready?
    @ready
  end

  # Turbo Frame attributes. The frame ships with NO `src` (a self-referential
  # `src` set in HTML no-ops on eager load and empties the frame); the
  # `job-status` controller owns fetching, driving the poll path on an interval.
  # Once ready both the controller and the poll path are dropped, so the ready
  # response frame has no controller — Stimulus tears the poller down on that
  # swap, which is exactly the stop signal.
  sig { returns(T::Hash[Symbol, T.untyped]) }
  def frame_attributes
    return {} if ready?

    {
      data: {
        controller: "job-status",
        job_status_interval_value: @poll.interval_ms,
        job_status_src_value: @poll.path
      }
    }
  end
end
