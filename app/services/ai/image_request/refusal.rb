# typed: true
# frozen_string_literal: true

require "json"

# Interprets an OpenRouter image-endpoint error as a content-policy refusal.
# OpenRouter signals a moderation block as an HTTP 400 whose error.code is
# "content_policy_violation" or "refusal", with reasons in error.metadata.
#
# .for(error) returns a Refused carrying the reason for such a block, else nil
# (the caller re-raises the original Faraday error so a key-attributable status
# still fails over in Ai::Funding). Faraday's error is untyped here (no RBI);
# its #response is a {status:, body:} hash, and on the error path the json
# middleware has not parsed the body, so it is the raw JSON string.
#
# Compact constant nesting (module Ai::ImageRequest::Refusal), rather than
# reopening the parent as a namespace, so the file introduces no bare
# class-keyword reopen of ImageRequest that check-service-modules would flag.
module Ai::ImageRequest::Refusal
  extend T::Sig

  CODES = T.let(%w[content_policy_violation refusal].freeze, T::Array[String])

  class << self
    extend T::Sig

    sig { params(error: T.untyped).returns(T.nilable(Ai::ImageRequest::Refused)) }
    def for(error)
      body = parse_json(response_body(error.response))
      code = body.dig("error", "code") if error_hash?(body)
      CODES.include?(code.to_s) ? Ai::ImageRequest::Refused.new(message(body)) : nil
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
      "OpenRouter blocked the image prompt on content-policy grounds#{": #{detail}" if detail}"
    end
  end
end
