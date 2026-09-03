# typed: true
# frozen_string_literal: true

require "json"

module Ai
  # A provider content-policy refusal — a general AI concept, not image-specific.
  # OpenRouter (and OpenAI-compatible endpoints behind it) signal a moderation
  # block as an HTTP 400 whose error.code is "content_policy_violation" or
  # "refusal", with reasons in error.metadata. Any Ai call (image generation,
  # summarization, …) can hit this, so the exception and its detection live here
  # at the Ai top level.
  #
  # Ai::Refusal::Error is the exception a caller rescues; Ai::Refusal.for(error)
  # turns a Faraday error into that exception (when the body is a policy block)
  # or nil (so the caller re-raises the original error — a key-attributable
  # status then fails over in Ai::Funding, the rest abort). Faraday's error is
  # untyped here (no RBI); its #response is a {status:, body:} hash, and on the
  # error path the json middleware has not parsed the body, so it is the raw
  # JSON string.
  module Refusal
    extend T::Sig

    # Raised when the provider refuses a call on content-policy grounds. Distinct
    # from a Faraday::Error (which means "this key can't fund the call") so the
    # caller reacts to it as a block rather than failing over.
    class Error < StandardError; end

    CODES = T.let(%w[content_policy_violation refusal].freeze, T::Array[String])

    class << self
      extend T::Sig

      sig { params(error: T.untyped).returns(T.nilable(Error)) }
      def for(error)
        body = parse_json(response_body(error.response))
        code = body.dig("error", "code") if error_hash?(body)
        CODES.include?(code.to_s) ? Error.new(message(body)) : nil
      end

      private

      sig { params(response: T.untyped).returns(T.untyped) }
      def response_body(response)
        response[:body] if response.is_a?(Hash)
      end

      sig { params(raw: T.untyped).returns(T.untyped) }
      def parse_json(raw)
        raw.is_a?(String) ? JSON.parse(raw) : raw
      rescue JSON::ParserError
        nil
      end

      sig { params(body: T.untyped).returns(T::Boolean) }
      def error_hash?(body)
        body.is_a?(Hash) && body["error"].is_a?(Hash)
      end

      sig { params(body: T::Hash[String, T.untyped]).returns(String) }
      def message(body)
        reasons = body.dig("error", "metadata", "reasons")
        detail = reasons.is_a?(Array) && reasons.any? ? reasons.join(", ") : body.dig("error", "message")
        "The AI provider blocked the request on content-policy grounds#{": #{detail}" if detail}"
      end
    end
  end
end
