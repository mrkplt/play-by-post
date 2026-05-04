require "rails_helper"

RSpec.describe SceneSummaryService do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game, title: "The Dungeon", description: "Dark and spooky") }

  before do
    create(:game_member, :game_master, game: game, user: gm)
  end

  describe "#call" do
    context "when OPENROUTER_API_KEY is not set" do
      it "raises ConfigurationError with a message about the key" do
        allow(ENV).to receive(:fetch).with("OPENROUTER_API_KEY", "").and_return("")
        expect { SceneSummaryService.new(scene).call }.to raise_error(
          SceneSummaryService::ConfigurationError, /OPENROUTER_API_KEY/
        )
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

      it "labels OOC posts with [OOC]" do
        player = create(:user, :with_profile)
        create(:game_member, game: game, user: player)
        create(:post, scene: scene, user: player, content: "dice roll ignored", is_ooc: true, draft: false)
        create(:post, scene: scene, user: player, content: "sword drawn", is_ooc: false, draft: false)

        expect(client_double).to receive(:chat) do |parameters:|
          content = parameters[:messages].first[:content]
          expect(content).to include("[OOC]")
          expect(content).to include("dice roll ignored")
          expect(content).to include("sword drawn")
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

      it "uses the author's display_name in post lines" do
        player = create(:user, :with_profile)
        create(:game_member, game: game, user: player)
        player.user_profile.update!(display_name: "Conan the Barbarian")
        create(:post, scene: scene, user: player, content: "I slash!", is_ooc: false, draft: false)

        expect(client_double).to receive(:chat) do |parameters:|
          content = parameters[:messages].first[:content]
          expect(content).to include("Conan the Barbarian")
          api_response
        end
        SceneSummaryService.new(scene).call
      end

      it "limits posts to MAX_POSTS" do
        player = create(:user, :with_profile)
        create(:game_member, game: game, user: player)
        stub_const("SceneSummaryService::MAX_POSTS", 2)
        create(:post, scene: scene, user: player, content: "post one", draft: false)
        create(:post, scene: scene, user: player, content: "post two", draft: false)
        create(:post, scene: scene, user: player, content: "post three", draft: false)

        expect(client_double).to receive(:chat) do |parameters:|
          content = parameters[:messages].first[:content]
          expect(content).to include("post one")
          expect(content).to include("post two")
          expect(content).not_to include("post three")
          api_response
        end
        SceneSummaryService.new(scene).call
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
end
