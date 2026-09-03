# typed: true
# frozen_string_literal: true

require "faraday"

module Ai
  # Screens a text prompt through OpenAI's Moderation API (omni-moderation-latest,
  # free) BEFORE an image generation spends a pool key. This is the app's own
  # infrastructure safety check (app_infra, funded by the app key), not a
  # game/BYOK feature.
  #
  # It returns a Verdict; the caller blocks generation when #flagged?. The
  # prompt screened is the full composed portrait prompt (safety preamble +
  # environment + player text). The image OUTPUT is not screened here — that is
  # a deliberate scope decision (plan §4): text pre-gen only. omni-moderation's
  # sexual/minors category is text-only anyway, so the pre-gen text screen is
  # where that signal is available.
  #
  # Like Ai::ImageRequest, the endpoint/auth is a configurable seam so the exact
  # transport can be pinned at deploy and stubbed in tests; downstream depends
  # only on the Verdict.
  class Moderation
    extend T::Sig

    DEFAULT_URL = "https://api.openai.com/v1/moderations"
    MODEL = "omni-moderation-latest"

    # The moderation outcome: whether the input was flagged, and the set of
    # violated category names (for logging a block). A frozen value object.
    class Verdict
      extend T::Sig

      sig { returns(T::Boolean) }
      attr_reader :flagged

      sig { returns(T::Array[String]) }
      attr_reader :categories

      sig { params(flagged: T::Boolean, categories: T::Array[String]).void }
      def initialize(flagged:, categories:)
        @flagged = flagged
        @categories = categories
        freeze
      end

      sig { returns(T::Boolean) }
      def flagged?
        @flagged
      end
    end

    sig { params(api_key: String, url: String, adapter: T.untyped).void }
    def initialize(api_key:, url: DEFAULT_URL, adapter: T.unsafe(Faraday).default_adapter)
      @api_key = api_key
      @url = url
      @adapter = adapter
    end

    # Screen `input` and return a Verdict. A transport failure propagates — the
    # caller decides whether a moderation outage should fail open or closed
    # (portraits fail CLOSED: a moderation error blocks generation, see the job).
    sig { params(input: String).returns(Verdict) }
    def call(input)
      response = connection.post(@url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(model: MODEL, input: input)
      end

      verdict_from(response.body)
    end

    private

    # Pure Faraday transport config; its mutations are either equivalent (T.unsafe
    # removal) or need a live socket to kill (timeout values, middleware presence).
    # Behaviour is covered end-to-end via the test adapter.
    sig { returns(T.untyped) }
    # mutant:disable
    def connection
      T.unsafe(Faraday).new do |f|
        f.request :authorization, "Bearer", @api_key
        f.response :json
        f.response :raise_error
        f.options.timeout = 15
        f.options.open_timeout = 10
        f.adapter(*Array(@adapter))
      end
    end

    # Parse the first result: `flagged` plus the names of every category whose
    # flag is true. A response without results is treated as flagged (fail
    # closed) rather than silently passing.
    sig { params(body: T.untyped).returns(Verdict) }
    def verdict_from(body)
      result = body.is_a?(Hash) ? Array(body["results"]).first : nil
      return Verdict.new(flagged: true, categories: [ "unparseable_moderation_response" ]) if result.nil?

      categories = (result["categories"] || {}).select { |_name, hit| hit }.keys
      Verdict.new(flagged: result["flagged"] == true, categories: categories)
    end
  end
end
