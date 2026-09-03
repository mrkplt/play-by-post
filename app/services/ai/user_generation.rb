# typed: strict

module Ai
  # The one engine every BYOK-funded AI generation routes through. This is what
  # makes "a BYOK call cannot happen unaudited" structural: every caller gets
  # back a Result carrying who funded it, so the caller can write the audit row
  # from what this returns — there is no path to an OpenRouter call that skips
  # producing that information.
  #
  # Owns the OpenRouter request itself (client construction, model resolution,
  # response parsing) behind Ai::Funding's pool/failover. Feature-specific
  # concerns — what the prompt says — live entirely in the caller (e.g.
  # SceneSummaryPrompt); this class only knows how to spend a key and parse
  # what comes back.
  class UserGeneration
    extend T::Sig

    OPENROUTER_API_BASE = "https://openrouter.ai/api/v1"

    Result = Struct.new(
      :body, :model_used, :input_tokens, :output_tokens, :cost, :funded_by,
      keyword_init: true
    ) do
      extend T::Sig

      # Parses an OpenRouter chat-completion response into a Result. Owned by
      # Result (not UserGeneration) since every field it reads comes from the
      # response, not from the caller's own state — except funded_by, which
      # comes from the Funding::Spend that wraps the response.
      #
      # `cost` reads OpenRouter's usage-accounting `usage.cost` field, which
      # OpenRouter includes in every chat-completion response with no opt-in
      # parameter required (their "Usage Accounting" cookbook: the deprecated
      # `usage: { include: true }` request flag is no longer needed). Left nil
      # if a response ever omits it rather than inventing a figure.
      sig { params(response: T::Hash[String, T.untyped], model_used: String, funded_by: User).returns(T.attached_class) }
      def self.from_response(response, model_used:, funded_by:)
        usage = response["usage"] || {}

        new(
          body: response.dig("choices", 0, "message", "content").to_s.strip,
          model_used: model_used,
          input_tokens: usage["prompt_tokens"],
          output_tokens: usage["completion_tokens"],
          cost: usage["cost"],
          funded_by: funded_by
        )
      end
    end

    sig { params(feature: String, game: Game, key_resolver: AiKeyResolver).void }
    def initialize(feature:, game:, key_resolver: AiKeyResolver.new(key_source: Crypto::StoredKeySource.new))
      @feature = feature
      @game = game
      @key_resolver = key_resolver
    end

    # Spends from the game's pool of authorized member keys (via Ai::Funding)
    # to run `prompt` through OpenRouter, and returns a Result carrying the
    # parsed response plus who funded it. Ai::Funding::Exhausted propagates
    # to the caller as-is — there is no app-key fallback for a BYOK-funded
    # call, and no ConfigurationError wrapper here; that is the caller's to
    # define in its own terms.
    sig { params(prompt: String).returns(Result) }
    def call(prompt:)
      spend = funding.call { |api_key| request_completion(api_key, prompt) }
      Result.from_response(spend.value, model_used: model, funded_by: spend.funded_by)
    end

    private

    sig { returns(Ai::Funding) }
    def funding
      Ai::Funding.new(resolver: @key_resolver, feature: @feature, game: @game)
    end

    sig { params(api_key: String, prompt: String).returns(T::Hash[String, T.untyped]) }
    def request_completion(api_key, prompt)
      client = OpenAI::Client.new(access_token: api_key, uri_base: OPENROUTER_API_BASE)
      client.chat(parameters: { model: model, messages: [ { role: "user", content: prompt } ] })
    end

    # The summarization model is required operational config — no default, so a
    # missing OPENROUTER_MODEL fails loudly (KeyError) rather than silently
    # summarizing with a stale model.
    sig { returns(String) }
    def model
      ENV.fetch("OPENROUTER_MODEL")
    end
  end
end
