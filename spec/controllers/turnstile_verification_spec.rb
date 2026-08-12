require "rails_helper"

# Unit coverage of the module via a minimal host controller.
RSpec.describe TurnstileVerification do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include TurnstileVerification
      attr_accessor :fake_params, :fake_request

      def params = fake_params
      def request = fake_request

      # Record whether the failure hook fired instead of rendering.
      attr_reader :failed

      def turnstile_verification_failed
        @failed = true
      end
    end
  end

  let(:controller) { controller_class.new }
  let(:request_double) { double("request", remote_ip: "198.51.100.9") }

  before do
    controller.fake_params = { "cf-turnstile-response" => "tok" }
    controller.fake_request = request_double
  end

  describe "#verify_turnstile!" do
    context "when Turnstile is disabled" do
      before { allow(Turnstile).to receive(:enabled?).and_return(false) }

      it "does not call the verifier and does not fail" do
        expect(TurnstileVerifier).not_to receive(:verify)
        controller.verify_turnstile!
        expect(controller.failed).to be_nil
      end
    end

    context "when Turnstile is enabled" do
      before { allow(Turnstile).to receive(:enabled?).and_return(true) }

      it "passes the submitted token and request remote_ip to the verifier" do
        expect(TurnstileVerifier).to receive(:verify)
          .with(token: "tok", remote_ip: "198.51.100.9").and_return(true)
        controller.verify_turnstile!
      end

      it "does not fail when the verifier returns true" do
        allow(TurnstileVerifier).to receive(:verify).and_return(true)
        controller.verify_turnstile!
        expect(controller.failed).to be_nil
      end

      it "invokes the failure hook when the verifier returns false" do
        allow(TurnstileVerifier).to receive(:verify).and_return(false)
        controller.verify_turnstile!
        expect(controller.failed).to be(true)
      end

      it "reads the token from the cf-turnstile-response param" do
        controller.fake_params = { "cf-turnstile-response" => "another" }
        expect(TurnstileVerifier).to receive(:verify)
          .with(hash_including(token: "another")).and_return(true)
        controller.verify_turnstile!
      end

      it "passes a nil token when the param is absent" do
        controller.fake_params = {}
        expect(TurnstileVerifier).to receive(:verify)
          .with(hash_including(token: nil)).and_return(false)
        controller.verify_turnstile!
      end
    end
  end

  describe "#turnstile_verification_failed (default)" do
    # The default implementation (not the test override) renders a 403. Verify it
    # against a real controller including the module without an override.
    let(:default_class) do
      Class.new(ActionController::Base) { include TurnstileVerification }
    end

    it "responds with head :forbidden" do
      instance = default_class.new
      expect(instance).to receive(:head).with(:forbidden)
      instance.send(:turnstile_verification_failed)
    end
  end
end
