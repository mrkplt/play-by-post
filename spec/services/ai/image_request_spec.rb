# typed: false

require "rails_helper"

# Ai::ImageRequest is the OpenRouter image POST and the boundary that classifies
# the response: success -> Result, content-policy refusal -> Refused,
# key-failure -> Faraday::Error propagates for pool failover.
#
# OpenRouter signals a content-moderation block as an HTTP 400 whose error.code
# is "content_policy_violation" or "refusal", with reasons in error.metadata.
#
# Tests drive the real #connection builder through Faraday's test adapter, so
# the middleware stack (auth header, JSON parse, raise_error, timeouts) is
# exercised for real rather than stubbed away.
RSpec.describe Ai::ImageRequest do
  # The test adapter is registered so ImageRequest's REAL #connection builder runs
  # (auth header, JSON parse, raise_error, timeouts) against a stubbed transport.
  # Named via constantize because Faraday ships no Sorbet RBI, so the nested
  # Faraday::Adapter::Test::Stubs constant won't statically resolve here.
  let(:stubs) { "Faraday::Adapter::Test::Stubs".constantize.new }
  subject(:request) { described_class.new(model: "some/image-model", prompt: "a knight", adapter: [ :test, stubs ]) }

  # Register a POST stub that records the request env, then returns the response.
  def stub_post(stubs, status, body, captured)
    stubs.post("https://openrouter.ai/api/v1/images") do |env|
      captured[:authorization] = env.request_headers["Authorization"]
      captured[:content_type] = env.request_headers["Content-Type"]
      captured[:body] = env.body
      [ status, { "Content-Type" => "application/json" }, JSON.generate(body) ]
    end
  end

  describe "#call" do
    it "posts the model and prompt with a bearer key and JSON content type" do
      captured = {}
      stub_post(stubs, 200, { "data" => [ { "b64_json" => Base64.strict_encode64("x") } ] }, captured)

      request.call("key-abc")

      expect(captured[:authorization]).to eq("Bearer key-abc")
      expect(captured[:content_type]).to eq("application/json")
      expect(JSON.parse(captured[:body])).to eq("model" => "some/image-model", "prompt" => "a knight")
    end

    it "returns a Result with decoded PNG bytes and cost on success" do
      png = "\x89PNG\r\n\x1a\n fake bytes".b
      stub_post(stubs, 200,
                { "data" => [ { "b64_json" => Base64.strict_encode64(png) } ], "usage" => { "cost" => 0.0123 } }, {})

      result = request.call("key-abc")

      expect(result.png_bytes).to eq(png)
      expect(result.cost).to eq(0.0123)
    end

    it "leaves cost nil when the response omits usage" do
      stub_post(stubs, 200, { "data" => [ { "b64_json" => Base64.strict_encode64("x") } ] }, {})
      expect(request.call("key-abc").cost).to be_nil
    end

    it "raises Refused on a 400 content_policy_violation, carrying the metadata reasons" do
      stub_post(stubs, 400, { "error" => {
        "code" => "content_policy_violation", "message" => "flagged",
        "metadata" => { "reasons" => [ "sexual", "minors" ] }
      } }, {})

      expect { request.call("key-abc") }.to raise_error(Ai::Refusal::Error, /sexual, minors/)
    end

    it "raises Refused on a 400 refusal code, falling back to the message when reasons are absent" do
      stub_post(stubs, 400, { "error" => { "code" => "refusal", "message" => "the model refused" } }, {})

      expect { request.call("key-abc") }.to raise_error(Ai::Refusal::Error, /the model refused/)
    end

    it "falls back to the message when the metadata reasons array is empty" do
      stub_post(stubs, 400, { "error" => {
        "code" => "content_policy_violation", "message" => "policy hit", "metadata" => { "reasons" => [] }
      } }, {})

      expect { request.call("key-abc") }.to raise_error(Ai::Refusal::Error, /policy hit/)
    end

    it "re-raises a 400 that is NOT a content-policy code (not a refusal)" do
      stub_post(stubs, 400, { "error" => { "code" => "invalid_request", "message" => "bad params" } }, {})

      expect { request.call("key-abc") }.to raise_error(Faraday::Error)
    end

    it "raises Refused when the response contains no image data" do
      stub_post(stubs, 200, { "data" => [] }, {})
      expect { request.call("key-abc") }.to raise_error(Ai::Refusal::Error, /no image data/)
    end

    it "raises Refused when the response has no data key at all" do
      stub_post(stubs, 200, {}, {})
      expect { request.call("key-abc") }.to raise_error(Ai::Refusal::Error, /no image data/)
    end

    it "lets a key-attributable HTTP failure propagate for pool failover" do
      stub_post(stubs, 401, { "error" => "bad key" }, {})

      # raise_error middleware turns the 401 into a Faraday::UnauthorizedError,
      # which Ai::Funding classifies as a key failure and fails over on.
      expect { request.call("key-abc") }.to raise_error(Faraday::Error) do |error|
        expect(error.response_status).to eq(401)
      end
    end
  end
end
