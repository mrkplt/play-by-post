# typed: false

require "rails_helper"

# Ai::ImageRequest::Refusal interprets a Faraday error from the OpenRouter image
# endpoint as a content-policy Refused, or nil for anything else. The error is
# untyped (a double exposing #response = { status:, body: <raw JSON string> }).
RSpec.describe Ai::ImageRequest::Refusal do
  def error_with(body:)
    double("Faraday::Error", response: { status: 400, body: body })
  end

  describe ".for" do
    it "returns a Refused with the metadata reasons for a content_policy_violation" do
      error = error_with(body: JSON.generate("error" => {
        "code" => "content_policy_violation", "message" => "flagged",
        "metadata" => { "reasons" => [ "sexual", "minors" ] }
      }))

      expect(described_class.for(error)).to be_a(Ai::ImageRequest::Refused)
      expect(described_class.for(error).message).to include("sexual, minors")
    end

    it "returns a Refused for a refusal code, using the message when reasons are absent" do
      error = error_with(body: JSON.generate("error" => { "code" => "refusal", "message" => "model refused" }))

      expect(described_class.for(error).message).to include("model refused")
    end

    it "falls back to the message when the reasons array is empty" do
      error = error_with(body: JSON.generate("error" => {
        "code" => "content_policy_violation", "message" => "policy hit", "metadata" => { "reasons" => [] }
      }))

      expect(described_class.for(error).message).to include("policy hit")
    end

    it "returns nil for a non-policy error code" do
      error = error_with(body: JSON.generate("error" => { "code" => "invalid_request" }))

      expect(described_class.for(error)).to be_nil
    end

    it "returns nil when the body is not JSON" do
      expect(described_class.for(error_with(body: "not json"))).to be_nil
    end

    it "returns nil when the error object is a bare string (not a hash)" do
      expect(described_class.for(error_with(body: JSON.generate("error" => "boom")))).to be_nil
    end

    it "returns nil when there is no response" do
      expect(described_class.for(double("Faraday::Error", response: nil))).to be_nil
    end
  end
end
