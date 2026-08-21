require "rails_helper"

RSpec.describe Crypto::Blob do
  describe ".from_json" do
    it "parses a well-formed blob" do
      json = { wrapped_key: "a", iv: "b", ciphertext: "c" }.to_json

      blob = described_class.from_json(json)

      expect(blob.wrapped_key).to eq("a")
      expect(blob.iv).to eq("b")
      expect(blob.ciphertext).to eq("c")
    end

    it "raises DecryptionError, with the parser's message, on invalid JSON" do
      expect { described_class.from_json("not json") }.to raise_error(
        Crypto::DecryptionError, /malformed sealed value blob/
      )
    end

    it "raises DecryptionError, naming the missing field, when a required field is missing" do
      json = { wrapped_key: "a", iv: "b" }.to_json

      expect { described_class.from_json(json) }.to raise_error(
        Crypto::DecryptionError, /malformed sealed value blob.*ciphertext/
      )
    end
  end

  describe ".from_params" do
    it "builds a Blob from already-permitted ActionController::Parameters" do
      permitted = ActionController::Parameters.new(wrapped_key: "a", iv: "b", ciphertext: "c").permit!

      blob = described_class.from_params(permitted)

      expect(blob.wrapped_key).to eq("a")
      expect(blob.iv).to eq("b")
      expect(blob.ciphertext).to eq("c")
    end

    it "raises KeyError when a required field is missing" do
      permitted = ActionController::Parameters.new(wrapped_key: "a", iv: "b").permit!

      expect { described_class.from_params(permitted) }.to raise_error(KeyError)
    end
  end
end
