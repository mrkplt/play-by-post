require "rails_helper"

# The browser error-report tunnel: a public, unauthenticated same-origin
# endpoint the Sentry SDK POSTs event envelopes to, which we forward to the
# self-hosted GlitchTip. Locked to our own DSN so it cannot become an open relay.
RSpec.describe ErrorTunnelController, type: :request do
  let(:our_dsn) { "https://pub@glitchtip.internal:9000/42" }

  before do
    allow(ErrorTracking).to receive(:parsed_dsn).and_return(GlitchTipDsn.new(our_dsn))
  end

  def post_envelope(body)
    post error_tunnel_path, params: body, headers: { "CONTENT_TYPE" => "application/x-sentry-envelope" }
  end

  # An envelope whose header names the given DSN, plus a trivial item.
  def envelope_for(dsn)
    %({"dsn":"#{dsn}"}\n{"type":"event"}\n{})
  end

  context "with an envelope addressed to our DSN" do
    it "enqueues the forward job with the raw envelope and answers 200" do
      body = envelope_for(our_dsn)
      expect(ErrorEnvelopeForwardJob).to receive(:perform_later).with(body)

      post_envelope(body)

      expect(response).to have_http_status(:ok)
    end

    it "reads only the first newline-delimited line as the header" do
      # A header line with internal spaces must still be parsed whole (guards
      # against splitting on whitespace instead of newlines); the item lines
      # after the first newline are not part of the header.
      body = %({"dsn": "#{our_dsn}", "sent_at": "2026-01-01"}\n{"type":"event"}\n{})
      expect(ErrorEnvelopeForwardJob).to receive(:perform_later).with(body)

      post_envelope(body)

      expect(response).to have_http_status(:ok)
    end
  end

  context "with an envelope addressed to a different host" do
    it "drops it — no job, 422" do
      expect(ErrorEnvelopeForwardJob).not_to receive(:perform_later)

      post_envelope(envelope_for("https://pub@evil.example/42"))

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "with an envelope addressed to a different project id on our host" do
    it "drops it — no job, 422" do
      expect(ErrorEnvelopeForwardJob).not_to receive(:perform_later)

      post_envelope(envelope_for("https://pub@glitchtip.internal:9000/999"))

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "with a malformed envelope" do
    it "drops a body whose header is not JSON" do
      expect(ErrorEnvelopeForwardJob).not_to receive(:perform_later)

      post_envelope("not json at all\n{}")

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "drops a body whose header carries no dsn" do
      expect(ErrorEnvelopeForwardJob).not_to receive(:perform_later)

      post_envelope(%({"sdk":"x"}\n{}))

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "drops a header whose dsn is present but malformed" do
      expect(ErrorEnvelopeForwardJob).not_to receive(:perform_later)

      post_envelope(%({"dsn":"not a url"}\n{}))

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "drops an empty body" do
      expect(ErrorEnvelopeForwardJob).not_to receive(:perform_later)

      post_envelope("")

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "when error tracking is not configured" do
    before { allow(ErrorTracking).to receive(:parsed_dsn).and_return(nil) }

    it "drops everything — no job, 422" do
      expect(ErrorEnvelopeForwardJob).not_to receive(:perform_later)

      post_envelope(envelope_for(our_dsn))

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
