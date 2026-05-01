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
      it "raises ConfigurationError" do
        allow(ENV).to receive(:fetch).with("OPENROUTER_API_KEY", "").and_return("")
        expect { SceneSummaryService.new(scene).call }.to raise_error(SceneSummaryService::ConfigurationError)
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
    end
  end
end
