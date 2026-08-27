# typed: true

# The scene-specific half of a scene summary generation: builds the prompt
# text handed to Ai::UserGeneration. Owns no OpenRouter/funding concerns —
# those live in Ai::UserGeneration, shared by every BYOK-funded AI feature.
class SceneSummaryPrompt
  extend T::Sig

  MAX_POSTS = 500

  sig { params(scene: Scene).void }
  def initialize(scene)
    @scene = scene
  end

  sig { returns(String) }
  def to_s
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

  private

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
end
