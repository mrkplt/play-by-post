# typed: true
# frozen_string_literal: true

require "base64"
require "faraday"

module Ai
  # One OpenRouter image-generation HTTP call: POST /api/v1/images with a model
  # and a prompt, funded by a single BYOK key, returning the decoded PNG bytes
  # and the reported cost.
  #
  # This class is the boundary that classifies the provider's response. The
  # three outcomes it distinguishes:
  #
  #   - success            → a Result (png bytes + cost).
  #   - a key-attributable HTTP failure (401/402/403/429) → a Faraday::Error
  #     propagates, so Ai::Funding fails over to the next pooled key exactly as
  #     for a chat generation.
  #   - a content-policy refusal → Ai::Refusal::Error, detected by Ai::Refusal
  #     (the shared, provider-level refusal concept). NOT a key failure and must
  #     not fail over (every key would refuse the same prompt).
  class ImageRequest
    extend T::Sig

    OPENROUTER_IMAGE_URL = "https://openrouter.ai/api/v1/images"

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

    # Run the generation with the given BYOK key. Returns a Result on success.
    # A Faraday error is handed to Ai::Refusal.for: a content-policy block becomes
    # an Ai::Refusal::Error, anything else re-raises (a key-attributable status
    # then fails over in Ai::Funding, the rest abort). Faraday carries no Sorbet
    # RBI here, so it is reached through T.unsafe — as EmailContentExtraction
    # reaches Net::HTTP.
    sig { params(api_key: String).returns(Result) }
    def call(api_key)
      success(post(api_key).body)
    rescue Faraday::Error => error
      raise Ai::Refusal.for(error) || error
    end

    private

    TIMEOUT = 60

    sig { params(api_key: String).returns(T.untyped) }
    def post(api_key)
      connection(api_key).post(OPENROUTER_IMAGE_URL) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(model: @model, prompt: @prompt)
      end
    end

    sig { params(api_key: String).returns(T.untyped) }
    def connection(api_key)
      HttpConnection.build(api_key: api_key, timeout: TIMEOUT, adapter: @adapter)
    end

    # A successful response body → a Result; a missing image (a 200 with no data)
    # is treated as a refusal rather than a silent nil.
    sig { params(body: T.untyped).returns(Result) }
    def success(body)
      first = first_image(body)
      raise Ai::Refusal::Error, "OpenRouter image response contained no image data" if first.nil?

      Result.new(png_bytes: Base64.decode64(first.fetch("b64_json")), cost: body.dig("usage", "cost"))
    end

    sig { params(body: T.untyped).returns(T.untyped) }
    def first_image(body)
      data = body.is_a?(Hash) ? body["data"] : nil
      data.is_a?(Array) ? data.first : nil
    end
  end
end
