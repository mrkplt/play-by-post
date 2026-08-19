require "rails_helper"

RSpec.describe GlitchTipDsn do
  subject(:dsn) { described_class.new("https://pubkey@glitchtip.internal:9000/42") }

  describe "#host" do
    it "is the DSN host" do
      expect(dsn.host).to eq("glitchtip.internal")
    end
  end

  describe "#project_id" do
    it "is the path with its leading slash removed" do
      expect(dsn.project_id).to eq("42")
    end

    it "raises InvalidDsn when the path carries no project id" do
      expect { described_class.new("https://pubkey@glitchtip.internal/").project_id }
        .to raise_error(GlitchTipDsn::InvalidDsn, /project id/)
    end
  end

  describe "#envelope_url" do
    it "is the Sentry-protocol envelope URL on the DSN's scheme, host and port, without userinfo" do
      expect(dsn.envelope_url).to eq("https://glitchtip.internal:9000/api/42/envelope/")
    end

    it "preserves an http scheme and default port" do
      plain = described_class.new("http://pubkey@glitchtip.internal/7")
      expect(plain.envelope_url).to eq("http://glitchtip.internal/api/7/envelope/")
    end

    it "strips both the public key and a secret from a legacy key:secret DSN" do
      # Older DSNs carried a secret ("<public>:<secret>@host"). Both halves of
      # the userinfo must be dropped, or the secret leaks into the ingest URL.
      legacy = described_class.new("https://pubkey:secret@glitchtip.internal/7")
      expect(legacy.envelope_url).to eq("https://glitchtip.internal/api/7/envelope/")
    end

    it "does not mutate the instance — host and project id survive the call" do
      # Building the URL works on a copy; without it, stripping the user and
      # rewriting the path would corrupt the DSN for any later host/project_id.
      dsn.envelope_url
      expect(dsn.host).to eq("glitchtip.internal")
      expect(dsn.project_id).to eq("42")
    end
  end

  describe "#same_project?" do
    it "is true for a DSN with the same host and project id (different public key)" do
      other = described_class.new("https://otherkey@glitchtip.internal:9000/42")
      expect(dsn.same_project?(other)).to be(true)
    end

    it "is false when the host differs" do
      other = described_class.new("https://pubkey@evil.example:9000/42")
      expect(dsn.same_project?(other)).to be(false)
    end

    it "is false when the project id differs" do
      other = described_class.new("https://pubkey@glitchtip.internal:9000/999")
      expect(dsn.same_project?(other)).to be(false)
    end
  end

  describe "validation on construction" do
    it "raises InvalidDsn for a DSN with no host" do
      expect { described_class.new("not-a-url") }
        .to raise_error(GlitchTipDsn::InvalidDsn, /host/)
    end

    it "raises InvalidDsn for a malformed URI rather than URI::InvalidURIError" do
      expect { described_class.new("http://[bad") }
        .to raise_error(GlitchTipDsn::InvalidDsn)
    end

    it "carries the underlying URI parse error message when the URI is malformed" do
      # The wrapped message is the URI parser's own, not the default class-name
      # message a nil would produce — so a misconfiguration is diagnosable.
      uri_message = begin
        URI.parse("http://[bad")
        nil
      rescue URI::InvalidURIError => e
        e.message
      end

      expect { described_class.new("http://[bad") }
        .to raise_error(GlitchTipDsn::InvalidDsn, uri_message)
    end
  end
end
