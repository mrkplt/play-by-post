require "rails_helper"

RSpec.describe TurnstileVerifier do
  # Stub the HTTP boundary; assert on what we send and how we interpret the reply.
  # A plain double (not instance_double) avoids partial-double verification
  # against Net::HTTPResponse's real interface.
  def stub_siteverify(body:)
    fake_response = double("Net::HTTPResponse", body: body)
    allow(Net::HTTP).to receive(:start).and_return(fake_response)
    fake_response
  end

  describe ".verify" do
    it "returns false for a blank token without calling siteverify" do
      expect(Net::HTTP).not_to receive(:start)
      expect(described_class.verify(token: "")).to be(false)
    end

    it "returns false for a nil token without calling siteverify" do
      expect(Net::HTTP).not_to receive(:start)
      expect(described_class.verify(token: nil)).to be(false)
    end

    it "returns true when Cloudflare reports success" do
      stub_siteverify(body: { success: true }.to_json)
      expect(described_class.verify(token: "tok")).to be(true)
    end

    it "returns false (fail closed) when Cloudflare reports failure" do
      stub_siteverify(body: { success: false, "error-codes" => [ "invalid-input-response" ] }.to_json)
      expect(described_class.verify(token: "bad")).to be(false)
    end

    it "treats a missing success key as failure" do
      stub_siteverify(body: {}.to_json)
      expect(described_class.verify(token: "tok")).to be(false)
    end

    it "treats a non-boolean-true success value as failure" do
      stub_siteverify(body: { success: "true" }.to_json)
      expect(described_class.verify(token: "tok")).to be(false)
    end

    context "fail open" do
      it "returns true when siteverify is unreachable (network error)" do
        allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)
        expect(described_class.verify(token: "tok")).to be(true)
      end

      it "returns true when siteverify times out" do
        allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)
        expect(described_class.verify(token: "tok")).to be(true)
      end

      it "returns true when siteverify returns an unparseable body" do
        stub_siteverify(body: "<html>502 Bad Gateway</html>")
        expect(described_class.verify(token: "tok")).to be(true)
      end
    end

    describe "request construction" do
      # Captures both the positional args passed to Net::HTTP.start (host, port,
      # options) and the request object, so the request target and body are both
      # asserted.
      def capture_request(&run)
        captured = {}
        allow(Net::HTTP).to receive(:start) do |*args, **kwargs, &blk|
          captured[:args] = args
          captured[:kwargs] = kwargs
          http = instance_double(Net::HTTP)
          allow(http).to receive(:request) do |req|
            captured[:request] = req
            double("Net::HTTPResponse", body: { success: true }.to_json)
          end
          blk.call(http)
        end
        run.call
        captured
      end

      it "connects to the Cloudflare siteverify host over SSL with the configured timeouts" do
        uri = URI.parse(Turnstile::SITEVERIFY_URL)
        captured = capture_request { described_class.verify(token: "t") }

        expect(captured[:args][0]).to eq(uri.hostname)
        expect(captured[:args][1]).to eq(uri.port)
        expect(captured[:kwargs]).to include(
          use_ssl: true,
          open_timeout: TurnstileVerifier::OPEN_TIMEOUT,
          read_timeout: TurnstileVerifier::READ_TIMEOUT
        )
      end

      it "posts the secret, token, and remote_ip in the form body" do
        captured = capture_request { described_class.verify(token: "the-token", remote_ip: "203.0.113.7") }
        body = captured[:request].body

        expect(body).to include("secret=#{Turnstile.secret_key}")
        expect(body).to include("response=the-token")
        expect(body).to include("remoteip=203.0.113.7")
      end

      it "coerces the token to a string in the body" do
        # Guards against dropping `.to_s`: set_form_data requires string values,
        # so a non-string token must be coerced.
        captured = capture_request { described_class.verify(token: "12345", remote_ip: nil) }
        expect(captured[:request].body).to include("response=12345")
      end

      it "omits remoteip when none is given" do
        captured = capture_request { described_class.verify(token: "the-token") }
        expect(captured[:request].body).not_to include("remoteip")
      end
    end
  end
end
