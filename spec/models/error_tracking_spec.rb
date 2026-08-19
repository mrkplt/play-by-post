require "rails_helper"

RSpec.describe ErrorTracking do
  describe ".dsn" do
    context "when the glitchtip credential is set" do
      before do
        allow(Rails.application.credentials).to receive(:glitchtip)
          .and_return(OpenStruct.new(dsn: "https://cred@glitchtip.internal/1"))
      end

      it "returns the credential DSN, ignoring the env var" do
        stub_env("GLITCHTIP_DSN", "https://env@glitchtip.internal/2") do
          expect(described_class.dsn).to eq("https://cred@glitchtip.internal/1")
        end
      end
    end

    context "when the credential is unset" do
      before do
        allow(Rails.application.credentials).to receive(:glitchtip).and_return(nil)
      end

      it "falls back to the GLITCHTIP_DSN env var" do
        stub_env("GLITCHTIP_DSN", "https://env@glitchtip.internal/2") do
          expect(described_class.dsn).to eq("https://env@glitchtip.internal/2")
        end
      end

      it "is nil when neither is configured" do
        stub_env("GLITCHTIP_DSN", nil) do
          expect(described_class.dsn).to be_nil
        end
      end
    end
  end

  describe ".enabled?" do
    it "is true when a DSN is configured" do
      allow(described_class).to receive(:dsn).and_return("https://cred@glitchtip.internal/1")
      expect(described_class.enabled?).to be(true)
    end

    it "is false when the DSN is nil" do
      allow(described_class).to receive(:dsn).and_return(nil)
      expect(described_class.enabled?).to be(false)
    end

    it "is false when the DSN is blank" do
      allow(described_class).to receive(:dsn).and_return("")
      expect(described_class.enabled?).to be(false)
    end
  end

  describe ".parsed_dsn" do
    it "returns a GlitchTipDsn parsed from the configured DSN" do
      allow(described_class).to receive(:dsn).and_return("https://cred@glitchtip.internal/9")
      parsed = described_class.parsed_dsn
      expect(parsed).to be_a(GlitchTipDsn)
      expect(parsed.project_id).to eq("9")
    end

    it "is nil when no DSN is configured" do
      allow(described_class).to receive(:dsn).and_return(nil)
      expect(described_class.parsed_dsn).to be_nil
    end

    it "is nil when the DSN is blank" do
      allow(described_class).to receive(:dsn).and_return("")
      expect(described_class.parsed_dsn).to be_nil
    end
  end

  describe ".own_project?" do
    let(:incoming) { GlitchTipDsn.new("https://pub@glitchtip.internal/42") }

    it "is true when the incoming DSN matches our configured project" do
      allow(described_class).to receive(:dsn).and_return("https://other@glitchtip.internal/42")
      expect(described_class.own_project?(incoming)).to be(true)
    end

    it "is false when the incoming DSN is a different project" do
      allow(described_class).to receive(:dsn).and_return("https://other@glitchtip.internal/99")
      expect(described_class.own_project?(incoming)).to be(false)
    end

    it "is false (not nil) when tracking is unconfigured" do
      allow(described_class).to receive(:dsn).and_return(nil)
      expect(described_class.own_project?(incoming)).to be(false)
    end
  end

  # Sets ENV[key] for the block and restores the prior value after — never leaks
  # a mutated env into another example.
  def stub_env(key, value)
    original = ENV[key]
    value.nil? ? ENV.delete(key) : ENV[key] = value
    yield
  ensure
    original.nil? ? ENV.delete(key) : ENV[key] = original
  end
end
