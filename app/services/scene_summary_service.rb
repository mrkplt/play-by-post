# typed: true

class SceneSummaryService
  extend T::Sig

  OPENROUTER_API_BASE = "https://openrouter.ai/api/v1"
  DEFAULT_MODEL = "openai/gpt-4o"
  MAX_POSTS = 500

  Result = Struct.new(:body, :model_used, :input_tokens, :output_tokens, keyword_init: true)

  sig { params(scene: Scene).void }
  def initialize(scene)
    @scene = scene
  end

  sig { returns(Result) }
  def call
    raise ConfigurationError, "OPENROUTER_API_KEY is not set" if api_key.blank?

    client = OpenAI::Client.new(
      access_token: api_key,
      uri_base: OPENROUTER_API_BASE
    )

    response = client.chat(
      parameters: {
        model: model,
        messages: [ { role: "user", content: prompt } ]
      }
    )

    body = response.dig("choices", 0, "message", "content").to_s.strip
    usage = response["usage"] || {}

    Result.new(
      body: body,
      model_used: model,
      input_tokens: usage["prompt_tokens"],
      output_tokens: usage["completion_tokens"]
    )
  end

  class ConfigurationError < StandardError; end

  private

  sig { returns(String) }
  def api_key
    ENV.fetch("OPENROUTER_API_KEY", "")
  end

  sig { returns(String) }
  def model
    ENV.fetch("OPENROUTER_MODEL", DEFAULT_MODEL)
  end

  sig { returns(String) }
  def prompt
    posts = @scene.posts.published.includes(:user).order(:created_at).limit(MAX_POSTS)

    post_lines = posts.map do |post|
      user = T.must(post.user)
      author = user.display_name || user.email
      prefix = post.is_ooc? ? "[OOC] " : ""
      "#{prefix}#{author}: #{post.content}"
    end.join("\n\n")

    description_section = @scene.description.present? ? "\nScene description: #{@scene.description}\n" : ""

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
