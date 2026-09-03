# typed: true
# frozen_string_literal: true

require "faraday"

module Ai
  # Screens a text prompt before an image generation spends a pool key. It calls
  # OpenAI's Moderation API (omni-moderation-latest, free) for the raw signal,
  # then hands the prompt and that result to every Ai::Moderation::Rule. Each
  # rule independently enforces one policy and returns an Outcome; if ANY rule
  # moderates, the request is blocked and every failing reason is collected for
  # the alert and the user-facing violation notice.
  #
  # The rules ARE the enforcement (they replace an inline flagged-category check):
  # the API result is just an input to them. Adding a rule is adding a
  # Rule subclass — Rule.descendants discovers it, no registry here.
  #
  # This is the app's own infrastructure safety check (app_infra, funded by the
  # app key), not a game/BYOK feature. Endpoint/auth is a configurable seam so
  # the transport can be pinned at deploy and stubbed in tests; downstream
  # depends only on the Verdict.
  #
  # Scope (plan §4): TEXT pre-gen only — the image output is not screened.
  class Moderation
    extend T::Sig

    DEFAULT_URL = "https://api.openai.com/v1/moderations"
    MODEL = "omni-moderation-latest"

    # The aggregate outcome across all rules: whether generation is blocked, and
    # the reasons from every rule that moderated (for the alert + user notice).
    class Verdict < T::Struct
      extend T::Sig

      const :flagged, T::Boolean
      const :reasons, T::Array[String]

      sig { returns(T::Boolean) }
      def flagged?
        flagged
      end
    end

    # `rules` is injectable so specs drive the aggregation with fake rules and
    # never depend on which concrete rules exist or on their loading. It defaults
    # to one instance of every concrete Rule subclass; at runtime the app is
    # eager-loaded (config.eager_load), so every rule file is loaded and present
    # in descendants.
    sig { params(api_key: String, url: String, adapter: T.untyped, rules: T::Array[Rule]).void }
    def initialize(api_key:, url: DEFAULT_URL, adapter: T.unsafe(Faraday).default_adapter, rules: default_rules)
      @api_key = api_key
      @url = url
      @adapter = adapter
      @rules = rules
    end

    # Screen `input`: fetch the moderation result, run every rule over it, and
    # aggregate. A transport failure propagates — the caller (the job) fails
    # closed and blocks generation.
    sig { params(input: String).returns(Verdict) }
    def call(input)
      result = fetch_result(input)
      blocking = @rules.map { |rule| rule.moderate(input, result) }.select(&:moderated?)

      Verdict.new(flagged: blocking.any?, reasons: blocking.map(&:reason))
    end

    TIMEOUT = 15

    private

    # One instance of every concrete Rule subclass — a new rule needs only a new
    # subclass, no registration here.
    sig { returns(T::Array[Rule]) }
    def default_rules
      T.unsafe(Rule).descendants.map(&:new)
    end

    # The parsed first `results` entry from the Moderation API (Hash with
    # "flagged"/"categories"/"category_scores"), or {} when the response has no
    # usable result — rules then see an empty result and a strict rule (e.g.
    # MinorSafety) treats a missing score as safe, while the caller still errors
    # closed on a transport failure (which raises rather than returning {}).
    sig { params(input: String).returns(T::Hash[String, T.untyped]) }
    def fetch_result(input)
      body = post_moderation(input).body
      first = body.is_a?(Hash) ? Array(body["results"]).first : nil
      first.is_a?(Hash) ? first : {}
    end

    sig { params(input: String).returns(T.untyped) }
    def post_moderation(input)
      connection.post(@url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(model: MODEL, input: input)
      end
    end

    sig { returns(T.untyped) }
    def connection
      HttpConnection.build(api_key: @api_key, timeout: TIMEOUT, adapter: @adapter)
    end
  end
end
