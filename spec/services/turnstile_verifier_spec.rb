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
      it "posts the secret, token, and remote_ip to the siteverify URL" do
        captured = nil
        allow(Net::HTTP).to receive(:start) do |*_args, &blk|
          http = instance_double(Net::HTTP)
          allow(http).to receive(:request) do |req|
            captured = req
            double("Net::HTTPResponse", body: { success: true }.to_json)
          end
          blk.call(http)
        end

        described_class.verify(token: "the-token", remote_ip: "203.0.113.7")

        expect(captured.body).to include("secret=#{Turnstile.secret_key}")
        expect(captured.body).to include("response=the-token")
        expect(captured.body).to include("remoteip=203.0.113.7")
      end

      it "omits remoteip when none is given" do
        captured = nil
        allow(Net::HTTP).to receive(:start) do |*_args, &blk|
          http = instance_double(Net::HTTP)
          allow(http).to receive(:request) do |req|
            captured = req
            double("Net::HTTPResponse", body: { success: true }.to_json)
          end
          blk.call(http)
        end

        described_class.verify(token: "the-token")

        expect(captured.body).not_to include("remoteip")
      end
    end
  end
end
