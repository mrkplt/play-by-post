require "rails_helper"

RSpec.describe SceneSummaryPrompt do
  let(:prompt_scene) { build_stubbed(:scene, description: "A dark tavern") }
  let(:prompt) { described_class.new(prompt_scene) }

  def post_double(content:, author: "Dana", ooc: false)
    double(user: double(display_name: author, email: "d@example.com"), is_ooc?: ooc, content: content)
  end

  def prompt_for(posts)
    allow(prompt).to receive(:posts_for_prompt).and_return(posts)
    prompt.to_s
  end

  it "labels OOC posts" do
    content = prompt_for([ post_double(content: "dice roll", ooc: true),
                           post_double(content: "sword drawn") ])

    expect(content).to include("[OOC] Dana: dice roll")
    expect(content).to include("Dana: sword drawn")
    expect(content).not_to include("[OOC] Dana: sword drawn")
  end

  it "uses the author display name" do
    expect(prompt_for([ post_double(content: "I slash!", author: "Conan the Barbarian") ]))
      .to include("Conan the Barbarian: I slash!")
  end

  it "falls back to the email when there is no display name" do
    expect(prompt_for([ post_double(content: "hi", author: nil) ])).to include("d@example.com: hi")
  end

  it "includes the scene description when present" do
    expect(prompt_for([])).to include("Scene description: A dark tavern")
  end

  it "renders the full prompt template byte for byte" do
    titled_scene = build_stubbed(:scene, title: "The Sunken Tavern", description: "A dark tavern")
    titled_prompt = described_class.new(titled_scene)
    posts = [ post_double(content: "dice roll", ooc: true), post_double(content: "sword drawn") ]
    allow(titled_prompt).to receive(:posts_for_prompt).and_return(posts)

    expected = <<~PROMPT
      You are a campaign chronicler for a tabletop RPG. Write a narrative summary of
      the following scene as it would appear in a campaign log — vivid, in-character
      prose, past tense, no game-mechanics language.

      Scene title: The Sunken Tavern
      Scene description: A dark tavern


      Posts (in chronological order):
      [OOC] Dana: dice roll

      Dana: sword drawn

      Rules:
      - Posts marked [OOC] are out-of-character. Include their content only when it
        directly shapes the fiction (e.g. a player describing their character's inner
        state). Ignore dice rolls, rule references, scheduling notes, and table talk.
      - Write from an omniscient narrator perspective; do not invent events not present
        in the posts.
      - Length: 150–400 words unless the scene warrants more.
    PROMPT

    expect(titled_prompt.to_s).to eq(expected)
  end

  it "renders the full prompt template byte for byte with no description and no posts" do
    bare_scene = build_stubbed(:scene, title: "The Sunken Tavern", description: "")
    bare_prompt = described_class.new(bare_scene)
    allow(bare_prompt).to receive(:posts_for_prompt).and_return([])

    expected = <<~PROMPT
      You are a campaign chronicler for a tabletop RPG. Write a narrative summary of
      the following scene as it would appear in a campaign log — vivid, in-character
      prose, past tense, no game-mechanics language.

      Scene title: The Sunken Tavern

      Posts (in chronological order):


      Rules:
      - Posts marked [OOC] are out-of-character. Include their content only when it
        directly shapes the fiction (e.g. a player describing their character's inner
        state). Ignore dice rolls, rule references, scheduling notes, and table talk.
      - Write from an omniscient narrator perspective; do not invent events not present
        in the posts.
      - Length: 150–400 words unless the scene warrants more.
    PROMPT

    expect(bare_prompt.to_s).to eq(expected)
  end

  describe "#posts_for_prompt" do
    it "takes published posts with their user, oldest first, capped at MAX_POSTS" do
      scene = build_stubbed(:scene)
      chain = double
      allow(chain).to receive(:includes).and_return(chain)
      allow(chain).to receive(:order).and_return(chain)
      allow(chain).to receive(:limit).and_return(chain)
      allow(chain).to receive(:to_a).and_return([])
      allow(scene).to receive(:posts).and_return(double(published: chain))

      described_class.new(scene).send(:posts_for_prompt)

      expect(chain).to have_received(:includes).with(:user)
      expect(chain).to have_received(:order).with(:created_at)
      expect(chain).to have_received(:limit).with(described_class::MAX_POSTS)
    end

    it "caps at five hundred" do
      expect(described_class::MAX_POSTS).to eq(500)
    end
  end
end
