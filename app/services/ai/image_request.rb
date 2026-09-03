# typed: true
# frozen_string_literal: true

require "base64"
require "faraday"

module Ai
  # One OpenRouter image-generation HTTP call: POST /api/v1/images with a model
  # and a prompt, funded by a single BYOK key, returning the decoded PNG bytes
  # and the reported cost.
  #
  # This class is the boundary that classifies the provider's response, and it
  # is deliberately the STUB SEAM for the not-yet-pinned-down OpenRouter refusal
  # shape (plan §7). The three outcomes it distinguishes:
  #
  #   - success            → a Result (png bytes + cost).
  #   - a key-attributable HTTP failure (401/402/403/429) → a Faraday::Error
  #     propagates, so Ai::Funding fails over to the next pooled key exactly as
  #     for a chat generation.
  #   - a content-policy refusal → Ai::ImageRequest::Refused, which the caller
  #     turns into the punitive lock path. NOT a key failure — it must not fail
  #     over to another key (every key would refuse the same disallowed prompt).
  #
  # Everything downstream depends only on the typed Refused, never on the wire
  # shape, so pinning down the real OpenRouter refusal payload later is a change
  # confined to #classify here.
  class ImageRequest
    extend T::Sig

    OPENROUTER_IMAGE_URL = "https://openrouter.ai/api/v1/images"

    # Raised when the provider refuses the prompt on content-policy grounds.
    # Distinct from a Faraday::Error (which means "this key can't fund the
    # call") so the caller can react punitively rather than fail over.
    class Refused < StandardError; end

    # The parsed result of a successful image generation.
    Result = Struct.new(:png_bytes, :cost, keyword_init: true)

    # `adapter` is the Faraday adapter, injectable so specs can drive the real
    # middleware stack through Faraday's test adapter instead of the net_http
    # transport (a Symbol, or [:test, stubs] in specs). Production uses the
    # default. Splatted into f.adapter, so both shapes work.
    sig { params(model: String, prompt: String, adapter: T.untyped).void }
    def initialize(model:, prompt:, adapter: T.unsafe(Faraday).default_adapter)
      @model = model
      @prompt = prompt
      @adapter = adapter
    end

    # Run the generation with the given BYOK key. Returns a Result on success;
    # raises Refused on a content-policy refusal; lets a key-attributable
    # Faraday::Error propagate for pool failover (Ai::Funding reads its
    # response_status). Faraday carries no Sorbet RBI here, so it is reached
    # through T.unsafe — the same way EmailContentExtraction reaches Net::HTTP.
    sig { params(api_key: String).returns(Result) }
    def call(api_key)
      response = connection(api_key).post(OPENROUTER_IMAGE_URL) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(model: @model, prompt: @prompt)
      end

      classify(response.body)
    end

    private

    TIMEOUT = 60

    sig { params(api_key: String).returns(T.untyped) }
    def connection(api_key)
      HttpConnection.build(api_key: api_key, timeout: TIMEOUT, adapter: @adapter)
    end

    # Turn a parsed response body into a Result, or raise Refused. This is the
    # stub seam: the refusal detection is coded against a placeholder shape (an
    # explicit `error.type == "moderation"` marker) and revisited once the real
    # OpenRouter image refusal payload is known — a change confined here.
    sig { params(body: T.untyped).returns(Result) }
    def classify(body)
      raise Refused, refusal_message(body) if refused?(body)

      first = first_image(body)
      raise Refused, "OpenRouter image response contained no image data" if first.nil?

      Result.new(png_bytes: Base64.decode64(first.fetch("b64_json")), cost: body.dig("usage", "cost"))
    end

    sig { params(body: T.untyped).returns(T.untyped) }
    def first_image(body)
      data = body.is_a?(Hash) ? body["data"] : nil
      data.is_a?(Array) ? data.first : nil
    end

    sig { params(body: T.untyped).returns(T::Boolean) }
    def refused?(body)
      return false unless body.is_a?(Hash)

      body.dig("error", "type") == "moderation"
    end

    sig { params(body: T.untyped).returns(String) }
    def refusal_message(body)
      body.dig("error", "message") || "OpenRouter refused the image prompt on content-policy grounds"
    end
  end
end
