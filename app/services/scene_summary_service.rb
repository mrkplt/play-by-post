# typed: true

class SceneSummaryService
  extend T::Sig

  OPENROUTER_API_BASE = "https://openrouter.ai/api/v1"
  DEFAULT_MODEL = "openai/gpt-4o"
  MAX_POSTS = 500

  Result = Struct.new(:body, :model_used, :input_tokens, :output_tokens, :cost, keyword_init: true) do
    # Parses an OpenRouter chat-completion response into a Result. Owned by
    # Result (not SceneSummaryService) since every field it reads comes from
    # the response, not from the caller's own state.
    #
    # `cost` reads OpenRouter's usage-accounting `usage.cost` field, which
    # OpenRouter includes in every chat-completion response with no opt-in
    # parameter required (their "Usage Accounting" cookbook: the deprecated
    # `usage: { include: true }` request flag is no longer needed). Left nil
    # if a response ever omits it rather than inventing a figure.
    def self.from_response(response, model_used:)
      usage = response["usage"] || {}

      new(
        body: response.dig("choices", 0, "message", "content").to_s.strip,
        model_used: model_used,
        input_tokens: usage["prompt_tokens"],
        output_tokens: usage["completion_tokens"],
        cost: usage["cost"]
      )
    end

    # The subset of scene_summaries columns this result supplies, so the job
    # doesn't reach across into each field individually (FeatureEnvy).
    def to_summary_attributes
      { body: body, model_used: model_used, input_tokens: input_tokens,
        output_tokens: output_tokens, cost: cost }
    end
  end

  FEATURE = "scene_summary"

  # HTTP statuses that mean "this particular key can't fund the call" — bad or
  # unauthorized key (401/403), no credit / over quota (402), rate-limited
  # (429). On these the worker fails over to the next key in the pool. Any
  # other failure (bad request, network, 5xx, timeout) is not the key's fault
  # and aborts the whole run rather than burning the rest of the pool.
  KEY_FAILURE_STATUSES = T.let([ 401, 402, 403, 429 ].freeze, T::Array[Integer])

  sig { params(scene: Scene, key_resolver: AiKeyResolver).void }
  def initialize(scene, key_resolver: AiKeyResolver.new(key_source: Crypto::StoredKeySource.new))
    @scene = scene
    @key_resolver = key_resolver
  end

  sig { returns(Result) }
  def call
    Result.from_response(request_completion_with_failover, model_used: model)
  end

  # Raised when this scene summary has no BYOK key to fund it — either the
  # game has no game master to resolve a player key for, or neither the game
  # master nor the game itself has a key configured (AiKeyResolver::NoKeyAvailable).
  # There is no app-key fallback for this player-facing AI call (see #api_key
  # removal below); SceneSummaryJob rescues this the same way it always
  # rescued a missing key.
  class ConfigurationError < StandardError; end

  private

  # A scene summary is a GAME-LEVEL output, so it is funded from the game's
  # pool of authorized member keys (GameKeyAuthorization), not one fixed
  # person. The resolver hands back a shuffled pool; we pop and try each in
  # turn, failing over only on a key-attributable failure. Any member's key
  # may fund it — the GM is not privileged.
  sig { returns(T::Hash[String, T.untyped]) }
  def request_completion_with_failover
    candidates = key_candidates

    loop do
      candidate = candidates.pop
      raise ConfigurationError, exhausted_message if candidate.nil?

      begin
        return request_completion(candidate.key)
      rescue Faraday::Error => error
        raise unless key_failure?(error)
        # This person's key can't fund it — drop it and try the next.
      end
    end
  end

  sig { returns(T::Array[AiKeyResolver::Candidate]) }
  def key_candidates
    @key_resolver.candidates(feature: FEATURE, game: T.must(@scene.game))
  rescue AiKeyResolver::NoKeyAvailable => error
    raise ConfigurationError, error.message
  end

  sig { params(error: Faraday::Error).returns(T::Boolean) }
  def key_failure?(error)
    KEY_FAILURE_STATUSES.include?(error.response_status)
  end

  sig { params(api_key: String).returns(T::Hash[String, T.untyped]) }
  def request_completion(api_key)
    client = OpenAI::Client.new(access_token: api_key, uri_base: OPENROUTER_API_BASE)
    client.chat(parameters: { model: model, messages: [ { role: "user", content: prompt } ] })
  end

  sig { returns(String) }
  def exhausted_message
    "Game ##{T.must(@scene.game).id} has no working BYOK OpenRouter key to fund a scene summary"
  end

  sig { returns(String) }
  def model
    ENV.fetch("OPENROUTER_MODEL", DEFAULT_MODEL)
  end

  # The prompt's only database read, isolated so the rendering above it can be
  # exercised with built posts.
  sig { returns(T::Array[Post]) }
  def posts_for_prompt
    @scene.posts.published.includes(:user).order(:created_at).limit(MAX_POSTS).to_a
  end

  # T.untyped so specs can render prompt output from plain doubles, decoupled
  # from real Post/User records (see spec's post_double helper).
  sig { params(post: T.untyped).returns(String) }
  def post_line(post)
    user = T.must(post.user)
    author = user.display_name || user.email
    prefix = post.is_ooc? ? "[OOC] " : ""
    "#{prefix}#{author}: #{post.content}"
  end

  sig { returns(String) }
  def description_section
    description = @scene.description
    description.present? ? "\nScene description: #{description}\n" : ""
  end

  sig { returns(String) }
  def prompt
    post_lines = posts_for_prompt.map { |post| post_line(post) }.join("\n\n")

    <<~PROMPT
      You are a campaign chronicler for a tabletop RPG. Write a narrative summary of
      the following scene as it would appear in a campaign log — vivid, in-character
      prose, past tense, no game-mechanics language.

      Scene title: #{@scene.title}#{description_section}

      Posts (in chronological order):
      #{post_lines}

      Rules:
      - Posts marked [OOC] are out-of-character. Include their content only when it
        directly shapes the fiction (e.g. a player describing their character's inner
        state). Ignore dice rolls, rule references, scheduling notes, and table talk.
      - Write from an omniscient narrator perspective; do not invent events not present
        in the posts.
      - Length: 150–400 words unless the scene warrants more.
    PROMPT
  end
end
