# typed: strict

module Ai
  # Runs a block against a game's pool of authorized member keys, failing over
  # on a key-attributable failure. The resolver hands back a shuffled pool; we
  # pop and yield each key in turn, and on a key failure (bad/unauthorized key,
  # no credit, rate-limit) drop it and try the next. Any other failure is not
  # the key's fault and propagates, aborting the run rather than burning the
  # rest of the pool. Exhausting the pool raises Exhausted.
  #
  # This is the worker-side "spend from the game's contribution pool" mechanism,
  # shared by every game-level AI feature (scene summaries now, portraits #19
  # later). It owns selection + failover; the caller owns the actual API call
  # (passed as the block) and its error types.
  class Funding
    extend T::Sig

    # HTTP statuses meaning "this particular key can't fund the call": bad or
    # unauthorized key (401/403), no credit / over quota (402), rate-limited
    # (429). On these we fail over to the next key. Anything else aborts.
    KEY_FAILURE_STATUSES = T.let([ 401, 402, 403, 429 ].freeze, T::Array[Integer])

    # Raised when every key in the pool failed on a key-attributable error, or
    # the pool was empty to begin with.
    class Exhausted < StandardError; end

    # The result of a successful funding call: the block's own return value,
    # plus who paid for it. `funded_by` is the User whose candidate key won —
    # the last one #attempt tried without a key-attributable failure. Callers
    # use this to write the audit trail; Funding itself never persists anything.
    class Spend
      extend T::Sig

      sig { returns(T.untyped) }
      attr_reader :value

      sig { returns(User) }
      attr_reader :funded_by

      sig { params(value: T.untyped, funded_by: User).void }
      def initialize(value:, funded_by:)
        @value = value
        @funded_by = funded_by
      end
    end

    sig { params(resolver: AiKeyResolver, feature: String, game: Game).void }
    def initialize(resolver:, feature:, game:)
      @resolver = resolver
      @feature = feature
      @game = game
    end

    # Yields each candidate's decrypted key to the block until one returns
    # without a key-attributable Faraday failure, and returns a Spend wrapping
    # that value with the winning candidate's user. The pool decrements as
    # keys fail — a failed key is popped and never retried.
    sig { params(block: T.proc.params(key: String).returns(T.untyped)).returns(Spend) }
    def call(&block)
      candidates = pool

      loop do
        candidate = candidates.pop
        result = attempt(candidate, &block)
        return Spend.new(value: result, funded_by: T.must(candidate).user) unless result.equal?(RETRY)
      end
    end

    private

    # Sentinel telling #call to pop the next candidate: distinguishes "the key
    # failed, try another" from a block that legitimately returned nil.
    RETRY = T.let(Object.new.freeze, Object)

    # One funding attempt: an exhausted pool raises, a key-attributable failure
    # returns RETRY (pop the next), anything else is the block's own result or
    # an aborting error propagated as-is.
    sig { params(candidate: T.nilable(AiKeyResolver::Candidate), block: T.proc.params(key: String).returns(T.untyped)).returns(T.untyped) }
    def attempt(candidate, &block)
      raise Exhausted, exhausted_message if candidate.nil?

      block.call(candidate.key)
    rescue Faraday::Error => error
      raise unless key_failure?(error)

      RETRY
    end

    sig { returns(T::Array[AiKeyResolver::Candidate]) }
    def pool
      @resolver.candidates(feature: @feature, game: @game)
    rescue AiKeyResolver::NoKeyAvailable => error
      raise Exhausted, error.message
    end

    sig { params(error: Faraday::Error).returns(T::Boolean) }
    def key_failure?(error)
      KEY_FAILURE_STATUSES.include?(error.response_status)
    end

    sig { returns(String) }
    def exhausted_message
      "Game ##{@game.id} has no working BYOK OpenRouter key to fund #{@feature}"
    end
  end
end
