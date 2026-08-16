# typed: true

class SceneSummaryService
  extend T::Sig

  OPENROUTER_API_BASE = "https://openrouter.ai/api/v1"
  DEFAULT_MODEL = "openai/gpt-4o"
  MAX_POSTS = 500

  Result = Struct.new(:body, :model_used, :input_tokens, :output_tokens, keyword_init: true) do
    # Parses an OpenRouter chat-completion response into a Result. Owned by
    # Result (not SceneSummaryService) since every field it reads comes from
    # the response, not from the caller's own state.
    def self.from_response(response, model_used:)
      usage = response["usage"] || {}

      new(
        body: response.dig("choices", 0, "message", "content").to_s.strip,
        model_used: model_used,
        input_tokens: usage["prompt_tokens"],
        output_tokens: usage["completion_tokens"]
      )
    end
  end

  sig { params(scene: Scene).void }
  def initialize(scene)
    @scene = scene
  end

  sig { returns(Result) }
  def call
    ensure_api_key!
    Result.from_response(request_completion, model_used: model)
  end

  class ConfigurationError < StandardError; end

  private

  sig { void }
  def ensure_api_key!
    return if api_key.present?

    raise ConfigurationError,
          "OpenRouter API key is not set (credentials.openrouter_api_key or OPENROUTER_API_KEY)"
  end

  sig { returns(T::Hash[String, T.untyped]) }
  def request_completion
    client = OpenAI::Client.new(access_token: api_key, uri_base: OPENROUTER_API_BASE)
    client.chat(parameters: { model: model, messages: [ { role: "user", content: prompt } ] })
  end

  # Reads the encrypted credential first so this matches EmailContentExtractor;
  # the env var remains a fallback for local runs without the credentials key.
  sig { returns(String) }
  def api_key
    Rails.application.credentials.openrouter_api_key.presence ||
      ENV.fetch("OPENROUTER_API_KEY", "")
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
