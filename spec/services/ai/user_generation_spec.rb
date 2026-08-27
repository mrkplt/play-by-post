require "rails_helper"

RSpec.describe Ai::UserGeneration do
  # A real implementer of the KeySource interface, not a plain double:
  # AiKeyResolver#initialize sig-types `key_source:` to AiKeyResolver::KeySource,
  # and sorbet-runtime rejects an RSpec double against a concrete interface
  # type (see docs/TESTING_NOTES.md, "Sorbet + sorbet-runtime + specs"; same
  # pattern as spec/services/ai_key_resolver_spec.rb). Its methods are still
  # stubbed per-example via allow/have_received.
  class UserGenerationFakeKeySource
    include AiKeyResolver::KeySource

    # Each person's decrypted key is derived from their id so a per-key failure
    # can be simulated deterministically (a status raised for a specific key).
    def for_user(user) = "key-#{user.id}"
  end

  let(:game) { create(:game) }
  let(:funder) { create(:user, :with_profile) }
  let(:feature) { "scene_summary" }
  let(:key_source) { UserGenerationFakeKeySource.new }
  let(:key_resolver) { AiKeyResolver.new(key_source: key_source) }
  subject(:generation) { described_class.new(feature: feature, game: game, key_resolver: key_resolver) }

  def authorize_funder(user)
    allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
    create(:game_key_authorization, game: game, user: user, feature: feature)
  end

  def faraday_error(status)
    error = Faraday::Error.new("boom")
    allow(error).to receive(:response_status).and_return(status)
    error
  end

  describe "#call" do
    context "when the game has no available key in the pool" do
      it "propagates Ai::Funding::Exhausted" do
        expect { generation.call(prompt: "hello") }.to raise_error(Ai::Funding::Exhausted)
      end
    end

    context "with a resolvable BYOK key in the pool" do
      let(:client_double) { instance_double(OpenAI::Client) }
      let(:api_response) do
        {
          "choices" => [ { "message" => { "content" => "A great adventure unfolded." } } ],
          "usage" => { "prompt_tokens" => 200, "completion_tokens" => 50, "cost" => 0.0042 }
        }
      end

      before do
        authorize_funder(funder)
        allow(ENV).to receive(:fetch).with("OPENROUTER_MODEL", described_class::DEFAULT_MODEL).and_return("openai/gpt-4o")
        allow(OpenAI::Client).to receive(:new).and_return(client_double)
        allow(client_double).to receive(:chat).and_return(api_response)
      end

      it "funds the call from an authorized member's key" do
        expect(OpenAI::Client).to receive(:new).with(
          access_token: "key-#{funder.id}",
          uri_base: described_class::OPENROUTER_API_BASE
        ).and_return(client_double)
        generation.call(prompt: "hello")
      end

      it "sends the given prompt as the message content" do
        expect(client_double).to receive(:chat) do |parameters:|
          expect(parameters[:messages]).to eq([ { role: "user", content: "hello there" } ])
          api_response
        end
        generation.call(prompt: "hello there")
      end

      it "returns a Result with body, token counts, cost, and funded_by" do
        result = generation.call(prompt: "hello")
        expect(result.body).to eq("A great adventure unfolded.")
        expect(result.model_used).to eq("openai/gpt-4o")
        expect(result.input_tokens).to eq(200)
        expect(result.output_tokens).to eq(50)
        expect(result.cost).to eq(0.0042)
        expect(result.funded_by).to eq(funder)
      end

      it "handles missing usage data gracefully" do
        allow(client_double).to receive(:chat).and_return(
          "choices" => [ { "message" => { "content" => "A story." } } ]
        )
        result = generation.call(prompt: "hello")
        expect(result.input_tokens).to be_nil
        expect(result.output_tokens).to be_nil
        expect(result.cost).to be_nil
      end

      it "returns empty string when API returns nil content" do
        allow(client_double).to receive(:chat).and_return(
          "choices" => [ { "message" => { "content" => nil } } ],
          "usage" => {}
        )
        result = generation.call(prompt: "hello")
        expect(result.body).to eq("")
      end
    end

    context "failover across the pool" do
      let(:client_double) { instance_double(OpenAI::Client) }
      let(:funder_a) { create(:user, :with_profile) }
      let(:funder_b) { create(:user, :with_profile) }
      let(:api_response) do
        { "choices" => [ { "message" => { "content" => "ok" } } ], "usage" => {} }
      end

      before do
        allow(ENV).to receive(:fetch).with("OPENROUTER_MODEL", described_class::DEFAULT_MODEL).and_return("openai/gpt-4o")
        allow(OpenAI::Client).to receive(:new).and_return(client_double)
      end

      def authorize_both
        allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
        create(:game_key_authorization, game: game, user: funder_a, feature: feature)
        create(:game_key_authorization, game: game, user: funder_b, feature: feature)
      end

      [ 401, 402, 403, 429 ].each do |status|
        it "fails over to the next key on a #{status} (key-attributable) failure" do
          authorize_both
          call_count = 0
          allow(client_double).to receive(:chat) do
            call_count += 1
            raise faraday_error(status) if call_count == 1
            api_response
          end

          result = generation.call(prompt: "hello")

          expect(result.body).to eq("ok")
          expect(call_count).to eq(2) # first key failed, second succeeded
          expect([ funder_a, funder_b ]).to include(result.funded_by)
        end
      end

      it "propagates Ai::Funding::Exhausted when every key in the pool fails on a key-attributable error" do
        authorize_both
        allow(client_double).to receive(:chat).and_raise(faraday_error(402))

        expect { generation.call(prompt: "hello") }.to raise_error(Ai::Funding::Exhausted, /no working BYOK/)
      end

      it "aborts the whole run on a non-key error without trying the rest of the pool" do
        authorize_both
        call_count = 0
        allow(client_double).to receive(:chat) do
          call_count += 1
          raise faraday_error(400)
        end

        expect { generation.call(prompt: "hello") }.to raise_error(Faraday::Error)
        expect(call_count).to eq(1) # did not fail over
      end
    end
  end

  describe "#initialize" do
    it "defaults the key resolver to AiKeyResolver backed by Crypto::StoredKeySource" do
      service = described_class.new(feature: feature, game: game)
      resolver = service.instance_variable_get(:@key_resolver)

      expect(resolver).to be_a(AiKeyResolver)
    end
  end
end
