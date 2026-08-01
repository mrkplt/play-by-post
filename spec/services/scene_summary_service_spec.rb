require "rails_helper"

RSpec.describe SceneSummaryService do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game, title: "The Dungeon", description: "Dark and spooky") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
  end

  describe "#call" do
    context "when no OpenRouter key is configured" do
      it "raises ConfigurationError with a message about the key" do
        allow(Rails.application.credentials).to receive(:openrouter_api_key).and_return(nil)
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("OPENROUTER_API_KEY", "").and_return("")
        expect { SceneSummaryService.new(scene).call }.to raise_error(
          SceneSummaryService::ConfigurationError, /openrouter_api_key/
        )
      end
    end

    context "when the key is in encrypted credentials" do
      let(:client_double) { instance_double(OpenAI::Client) }

      before do
        allow(Rails.application.credentials).to receive(:openrouter_api_key).and_return("cred-key")
        allow(ENV).to receive(:fetch).and_call_original
        allow(OpenAI::Client).to receive(:new).and_return(client_double)
        allow(client_double).to receive(:chat).and_return(
          { "choices" => [ { "message" => { "content" => "Summary." } } ], "usage" => {} }
        )
      end

      it "prefers the credential over the environment variable" do
        allow(ENV).to receive(:fetch).with("OPENROUTER_API_KEY", "").and_return("env-key")
        expect(OpenAI::Client).to receive(:new).with(
          hash_including(access_token: "cred-key")
        ).and_return(client_double)
        SceneSummaryService.new(scene).call
      end
    end

    context "with a valid API key" do
      let(:client_double) { instance_double(OpenAI::Client) }
      let(:api_response) do
        {
          "choices" => [ { "message" => { "content" => "A great adventure unfolded." } } ],
          "usage" => { "prompt_tokens" => 200, "completion_tokens" => 50 }
        }
      end

      before do
        # Credential absent, so the service falls back to the env var.
        allow(Rails.application.credentials).to receive(:openrouter_api_key).and_return(nil)
        allow(ENV).to receive(:fetch).with("OPENROUTER_API_KEY", "").and_return("test-key")
        allow(ENV).to receive(:fetch).with("OPENROUTER_MODEL", SceneSummaryService::DEFAULT_MODEL).and_return("openai/gpt-4o")
        allow(OpenAI::Client).to receive(:new).and_return(client_double)
        allow(client_double).to receive(:chat).and_return(api_response)
      end

      it "creates an OpenAI client pointing at the OpenRouter API base" do
        expect(OpenAI::Client).to receive(:new).with(
          access_token: "test-key",
          uri_base: SceneSummaryService::OPENROUTER_API_BASE
        ).and_return(client_double)
        SceneSummaryService.new(scene).call
      end

      it "returns a Result with body and token counts" do
        result = SceneSummaryService.new(scene).call
        expect(result.body).to eq("A great adventure unfolded.")
        expect(result.model_used).to eq("openai/gpt-4o")
        expect(result.input_tokens).to eq(200)
        expect(result.output_tokens).to eq(50)
      end

      it "includes the scene title in the prompt" do
        expect(client_double).to receive(:chat) do |parameters:|
          content = parameters[:messages].first[:content]
          expect(content).to include("The Dungeon")
          api_response
        end
        SceneSummaryService.new(scene).call
      end


      it "excludes draft posts" do
        player = create(:user, :with_profile)
        create(:post, scene: scene, user: player, content: "draft content", draft: true)

        expect(client_double).to receive(:chat) do |parameters:|
          content = parameters[:messages].first[:content]
          expect(content).not_to include("draft content")
          api_response
        end
        SceneSummaryService.new(scene).call
      end

      it "includes the scene description when present" do
        expect(client_double).to receive(:chat) do |parameters:|
          content = parameters[:messages].first[:content]
          expect(content).to include("Dark and spooky")
          api_response
        end
        SceneSummaryService.new(scene).call
      end

      it "omits the description section when absent" do
        scene_no_desc = create(:scene, :resolved, game: game, title: "No Desc", description: nil)
        expect(client_double).to receive(:chat) do |parameters:|
          content = parameters[:messages].first[:content]
          expect(content).not_to include("Scene description:")
          api_response
        end
        SceneSummaryService.new(scene_no_desc).call
      end



      it "does NOT label in-character posts with [OOC]" do
        player = create(:user, :with_profile)
        create(:game_member, game: game, user: player)
        create(:post, scene: scene, user: player, content: "sword drawn", is_ooc: false, draft: false)

        expect(client_double).to receive(:chat) do |parameters:|
          content = parameters[:messages].first[:content]
          line = content.lines.find { |l| l.include?("sword drawn") }
          expect(line).not_to start_with("[OOC]")
          api_response
        end
        SceneSummaryService.new(scene).call
      end

      it "handles missing usage data gracefully" do
        allow(client_double).to receive(:chat).and_return(
          "choices" => [ { "message" => { "content" => "A story." } } ]
        )
        result = SceneSummaryService.new(scene).call
        expect(result.input_tokens).to be_nil
        expect(result.output_tokens).to be_nil
      end

      it "returns empty string when API returns nil content" do
        allow(client_double).to receive(:chat).and_return(
          "choices" => [ { "message" => { "content" => nil } } ],
          "usage" => {}
        )
        result = SceneSummaryService.new(scene).call
        expect(result.body).to eq("")
      end
    end
  end

  # Prompt rendering over a post list; #posts_for_prompt is the only read.
  describe "#prompt" do
    let(:prompt_scene) { build_stubbed(:scene, description: "A dark tavern") }
    let(:service) { described_class.new(prompt_scene) }

    def post_double(content:, author: "Dana", ooc: false)
      double(user: double(display_name: author, email: "d@example.com"), is_ooc?: ooc, content: content)
    end

    def prompt_for(posts)
      allow(service).to receive(:posts_for_prompt).and_return(posts)
      service.send(:prompt)
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
      titled_service = described_class.new(titled_scene)
      posts = [ post_double(content: "dice roll", ooc: true), post_double(content: "sword drawn") ]
      allow(titled_service).to receive(:posts_for_prompt).and_return(posts)

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

      expect(titled_service.send(:prompt)).to eq(expected)
    end

    it "renders the full prompt template byte for byte with no description and no posts" do
      bare_scene = build_stubbed(:scene, title: "The Sunken Tavern", description: "")
      bare_service = described_class.new(bare_scene)
      allow(bare_service).to receive(:posts_for_prompt).and_return([])

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

      expect(bare_service.send(:prompt)).to eq(expected)
    end
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
