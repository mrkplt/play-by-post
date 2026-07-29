require "rails_helper"

RSpec.describe CoolifyDeployJob, type: :job do
  let(:deploy_url) { "http://coolify.internal:8000/api/v1/deploy?uuid=abc123" }
  let(:token) { "coolify-api-token" }
  let(:coolify_config) { double("coolify", deploy_url: deploy_url, token: token) }

  before do
    allow(Rails.application.credentials).to receive(:coolify).and_return(coolify_config)
  end

  # Stubs Net::HTTP.start to capture the issued request and return a canned
  # response, avoiding any real network call.
  def stub_http_response(response)
    captured = {}
    allow(Net::HTTP).to receive(:start) do |hostname, port, opts, &block|
      captured[:hostname] = hostname
      captured[:port] = port
      captured[:use_ssl] = opts[:use_ssl]
      http = double("http")
      allow(http).to receive(:request) do |request|
        captured[:request] = request
        response
      end
      block.call(http)
    end
    captured
  end

  describe "#perform" do
    it "sends an authorized GET to the Coolify deploy URL host" do
      captured = stub_http_response(Net::HTTPSuccess.new("1.1", "200", "OK"))

      described_class.new.perform

      expect(captured[:hostname]).to eq("coolify.internal")
      expect(captured[:port]).to eq(8000)
      expect(captured[:use_ssl]).to be(false)
      expect(captured[:request]["Authorization"]).to eq("Bearer #{token}")
      expect(captured[:request].path).to eq("/api/v1/deploy?uuid=abc123")
    end

    it "uses TLS for an https deploy URL" do
      allow(coolify_config).to receive(:deploy_url).and_return("https://coolify.example.com/api/v1/deploy?uuid=x")
      captured = stub_http_response(Net::HTTPSuccess.new("1.1", "200", "OK"))

      described_class.new.perform

      expect(captured[:use_ssl]).to be(true)
    end

    it "raises when Coolify returns a non-success response" do
      stub_http_response(Net::HTTPServerError.new("1.1", "500", "Internal Server Error"))

      expect { described_class.new.perform }.to raise_error(/Coolify deploy trigger failed: 500/)
    end

    context "when deploy_url is not configured" do
      let(:deploy_url) { nil }

      it "raises ConfigurationError referencing deploy_url" do
        expect { described_class.new.perform }
          .to raise_error(CoolifyDeployJob::ConfigurationError, /deploy_url/)
      end
    end

    context "when token is not configured" do
      let(:token) { nil }

      it "raises ConfigurationError referencing token" do
        expect { described_class.new.perform }
          .to raise_error(CoolifyDeployJob::ConfigurationError, /token/)
      end
    end

    context "when the coolify credential is entirely absent" do
      before do
        allow(Rails.application.credentials).to receive(:coolify).and_return(nil)
      end

      it "raises ConfigurationError" do
        expect { described_class.new.perform }
          .to raise_error(CoolifyDeployJob::ConfigurationError)
      end
    end
  end
end
