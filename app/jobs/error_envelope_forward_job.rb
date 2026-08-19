# typed: true

require "net/http"

# Forwards a browser error envelope to the self-hosted GlitchTip over the
# internal backplane.
#
# GlitchTip has no public ingress, so the browser SDK cannot report to it
# directly (its events would leave the LAN and never arrive). Instead the SDK is
# configured with a same-origin tunnel; ErrorTunnelController validates the
# envelope against our own DSN and enqueues it here, and this job — running
# inside the app, which *can* reach GlitchTip internally — POSTs the raw
# envelope bytes to the Sentry-protocol ingest endpoint. Structurally the same
# inside-the-app forward CoolifyDeployJob does for the (also private) Coolify.
#
# Best-effort telemetry: a forward that ultimately fails drops one error report,
# which is acceptable, so failures are logged rather than escalated.
class ErrorEnvelopeForwardJob < ApplicationJob
  extend T::Sig

  queue_as :default

  # A missing DSN means error tracking is disabled; nothing to forward, and it is
  # not retryable.
  class ConfigurationError < StandardError; end

  discard_on ConfigurationError

  sig { params(envelope: String).void }
  def perform(envelope)
    dsn = ErrorTracking.parsed_dsn
    raise ConfigurationError, "GlitchTip DSN is not configured" if dsn.nil?

    forward(dsn.envelope_url, envelope)
  end

  private

  sig { params(url: String, envelope: String).void }
  def forward(url, envelope)
    uri = URI.parse(url)
    log_failure(post(uri, envelope))
  end

  # Best-effort: a failed forward drops one error report, so it is logged rather
  # than raised. A successful response is a no-op.
  sig { params(response: Net::HTTPResponse).void }
  def log_failure(response)
    return if response.is_a?(Net::HTTPSuccess)

    Rails.logger.warn("GlitchTip envelope forward failed: #{response.code} #{response.message}")
  end

  sig { params(uri: URI::Generic, envelope: String).returns(Net::HTTPResponse) }
  def post(uri, envelope)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-sentry-envelope"
    request.body = envelope

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  end
end
