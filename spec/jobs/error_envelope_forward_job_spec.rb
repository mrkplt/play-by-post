require "rails_helper"

RSpec.describe ErrorEnvelopeForwardJob, type: :job do
  let(:envelope) { %({"dsn":"https://pub@glitchtip.internal:9000/42"}\n{"type":"event"}\n{}) }

  before do
    allow(ErrorTracking).to receive(:parsed_dsn)
      .and_return(GlitchTipDsn.new("https://pub@glitchtip.internal:9000/42"))
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
    it "POSTs the raw envelope bytes to the DSN's envelope ingest URL" do
      captured = stub_http_response(Net::HTTPOK.new("1.1", "200", "OK"))

      described_class.new.perform(envelope)

      expect(captured[:hostname]).to eq("glitchtip.internal")
      expect(captured[:port]).to eq(9000)
      expect(captured[:use_ssl]).to be(true)
      expect(captured[:request]).to be_a(Net::HTTP::Post)
      expect(captured[:request].path).to eq("/api/42/envelope/")
      expect(captured[:request]["Content-Type"]).to eq("application/x-sentry-envelope")
      expect(captured[:request].body).to eq(envelope)
    end

    it "uses plain HTTP for an http DSN" do
      allow(ErrorTracking).to receive(:parsed_dsn)
        .and_return(GlitchTipDsn.new("http://pub@glitchtip.internal/7"))
      captured = stub_http_response(Net::HTTPOK.new("1.1", "200", "OK"))

      described_class.new.perform(envelope)

      expect(captured[:use_ssl]).to be(false)
    end

    it "logs a warning but does not raise on a non-success response" do
      stub_http_response(Net::HTTPServerError.new("1.1", "500", "Internal Server Error"))
      expect(Rails.logger).to receive(:warn).with(/GlitchTip envelope forward failed: 500/)

      expect { described_class.new.perform(envelope) }.not_to raise_error
    end

    it "does not log a warning on a successful forward" do
      stub_http_response(Net::HTTPOK.new("1.1", "200", "OK"))
      expect(Rails.logger).not_to receive(:warn)

      described_class.new.perform(envelope)
    end

    context "when no DSN is configured" do
      before { allow(ErrorTracking).to receive(:parsed_dsn).and_return(nil) }

      it "raises ConfigurationError referencing the DSN and makes no HTTP call" do
        expect(Net::HTTP).not_to receive(:start)
        expect { described_class.new.perform(envelope) }
          .to raise_error(ErrorEnvelopeForwardJob::ConfigurationError, /DSN/)
      end

      it "discards the job rather than retrying (ConfigurationError)" do
        expect(described_class.new).to be_a(ApplicationJob)
        # discard_on ConfigurationError is declared on the class.
        expect(described_class.rescue_handlers.map(&:first))
          .to include("ErrorEnvelopeForwardJob::ConfigurationError")
      end
    end
  end
end
