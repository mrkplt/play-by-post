require "rails_helper"

RSpec.describe AiKeypairs::Blob do
  describe ".from_json" do
    it "parses a well-formed blob" do
      json = { wrapped_key: "a", iv: "b", ciphertext: "c" }.to_json

      blob = described_class.from_json(json)

      expect(blob.wrapped_key).to eq("a")
      expect(blob.iv).to eq("b")
      expect(blob.ciphertext).to eq("c")
    end

    it "raises DecryptionError on invalid JSON" do
      expect { described_class.from_json("not json") }.to raise_error(AiKeypairs::DecryptionError)
    end

    it "raises DecryptionError when a required field is missing" do
      json = { wrapped_key: "a", iv: "b" }.to_json

      expect { described_class.from_json(json) }.to raise_error(AiKeypairs::DecryptionError)
    end
  end
end
