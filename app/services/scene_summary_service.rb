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

  sig { params(scene: Scene, key_resolver: AiKeyResolver).void }
  def initialize(scene, key_resolver: AiKeyResolver.new(key_source: Crypto::StoredKeySource.new))
    @scene = scene
    @key_resolver = key_resolver
  end

  # A scene summary is a GAME-LEVEL output, funded from the game's pool of
  # authorized member keys (GameKeyAuthorization) via Ai::PooledFunding, which
  # owns the shuffle/pop/failover. Any member's key may fund it — the GM is not
  # privileged. An empty/exhausted pool becomes ConfigurationError, rescued by
  # SceneSummaryJob the same way a missing key always was.
  sig { returns(Result) }
  def call
    response = funding.call { |api_key| request_completion(api_key) }
    Result.from_response(response, model_used: model)
  rescue Ai::PooledFunding::Exhausted => error
    raise ConfigurationError, error.message
  end

  # Raised when this scene summary has no working BYOK key to fund it. There is
  # no app-key fallback for this player-facing AI call; SceneSummaryJob rescues
  # this the same way it always rescued a missing key.
  class ConfigurationError < StandardError; end

  private

  sig { returns(Ai::PooledFunding) }
  def funding
    Ai::PooledFunding.new(resolver: @key_resolver, feature: FEATURE, game: T.must(@scene.game))
  end

  sig { params(api_key: String).returns(T::Hash[String, T.untyped]) }
  def request_completion(api_key)
    client = OpenAI::Client.new(access_token: api_key, uri_base: OPENROUTER_API_BASE)
    client.chat(parameters: { model: model, messages: [ { role: "user", content: prompt } ] })
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
