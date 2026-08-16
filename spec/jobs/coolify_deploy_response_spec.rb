require "rails_helper"

RSpec.describe CoolifyDeployResponse do
  describe "#code" do
    it "reads the code off the wrapped response" do
      http_response = Net::HTTPSuccess.new("1.1", "200", "OK")

      expect(described_class.new(http_response).code).to eq("200")
    end
  end

  describe "#verify_success!" do
    it "does not raise for a success response" do
      # Net::HTTP always returns a concrete subclass (HTTPOK, HTTPCreated, ...),
      # never the literal Net::HTTPSuccess — so this must be `is_a?`-checked,
      # not `instance_of?`, to match real responses.
      http_response = Net::HTTPOK.new("1.1", "200", "OK")

      expect { described_class.new(http_response).verify_success! }.not_to raise_error
    end

    it "raises with the code and message for a non-success response" do
      http_response = Net::HTTPServerError.new("1.1", "500", "Internal Server Error")

      expect { described_class.new(http_response).verify_success! }
        .to raise_error("Coolify deploy trigger failed: 500 Internal Server Error")
    end

    it "raises for a client error response" do
      http_response = Net::HTTPClientError.new("1.1", "404", "Not Found")

      expect { described_class.new(http_response).verify_success! }
        .to raise_error(/Coolify deploy trigger failed: 404/)
    end
  end
end
