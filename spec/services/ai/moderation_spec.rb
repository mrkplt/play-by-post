# typed: false

require "rails_helper"

# Ai::Moderation screens a prompt through OpenAI's Moderation API before an image
# generation spends a key. It returns a Verdict; the caller blocks on #flagged?.
# The real #connection builder runs against Faraday's test adapter.
RSpec.describe Ai::Moderation do
  let(:stubs) { "Faraday::Adapter::Test::Stubs".constantize.new }
  subject(:moderation) { described_class.new(api_key: "app-key", adapter: [ :test, stubs ]) }

  def stub_post(status, body, captured = {})
    stubs.post("https://api.openai.com/v1/moderations") do |env|
      captured[:authorization] = env.request_headers["Authorization"]
      captured[:body] = env.body
      [ status, { "Content-Type" => "application/json" }, JSON.generate(body) ]
    end
  end

  describe "#call" do
    it "sends the model and input with the app bearer key" do
      captured = {}
      stub_post(200, { "results" => [ { "flagged" => false, "categories" => {} } ] }, captured)

      moderation.call("a knight")

      expect(captured[:authorization]).to eq("Bearer app-key")
      expect(JSON.parse(captured[:body])).to eq("model" => "omni-moderation-latest", "input" => "a knight")
    end

    it "returns an unflagged verdict when nothing is flagged" do
      stub_post(200, { "results" => [ { "flagged" => false, "categories" => { "sexual" => false } } ] })

      verdict = moderation.call("a knight")

      expect(verdict.flagged?).to be(false)
      expect(verdict.categories).to be_empty
    end

    it "returns a flagged verdict with the violated category names" do
      stub_post(200, { "results" => [ {
        "flagged" => true,
        "categories" => { "sexual" => true, "sexual/minors" => true, "violence" => false }
      } ] })

      verdict = moderation.call("disallowed text")

      expect(verdict.flagged?).to be(true)
      expect(verdict.categories).to contain_exactly("sexual", "sexual/minors")
    end

    it "fails closed (flagged) when the response has no results" do
      stub_post(200, {})

      verdict = moderation.call("x")

      expect(verdict.flagged?).to be(true)
      expect(verdict.categories).to eq([ "unparseable_moderation_response" ])
    end

    it "lets a transport error propagate so the caller can fail closed" do
      stub_post(500, { "error" => "server" })

      expect { moderation.call("x") }.to raise_error(Faraday::Error)
    end
  end
end
