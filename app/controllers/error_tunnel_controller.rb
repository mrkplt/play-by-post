# typed: true

require "json"

# Same-origin tunnel for browser error reports (Sentry SDK `tunnel` option).
#
# GlitchTip is self-hosted with no public ingress, so the browser SDK cannot
# POST to it directly. Instead it POSTs the raw event *envelope* here, and we
# forward it to GlitchTip over the internal backplane (ErrorEnvelopeForwardJob).
#
# This endpoint is unauthenticated by necessity — logged-out visitors throw
# errors too, and the SDK sends no session or CSRF token. To keep it from being
# an open relay to arbitrary Sentry hosts, every envelope is validated against
# *our* configured DSN: the envelope header's DSN host and project id must match
# ours, or the request is dropped. The forwarded bytes go only to our own DSN's
# ingest URL, never to a host named in the incoming envelope.
#
# A sibling of ApplicationController (not a subclass) so it never touches Warden,
# a session, or Devise's authenticate_user! — like DataApplicationController,
# but with no authentication at all.
class ErrorTunnelController < ActionController::Base
  extend T::Sig

  # No CSRF token exists on a cross-page SDK POST; never fall back to a session.
  protect_from_forgery with: :null_session

  sig { void }
  def create
    envelope = request.body.read

    unless matches_our_dsn?(envelope)
      head :unprocessable_content
      return
    end

    ErrorEnvelopeForwardJob.perform_later(envelope)
    head :ok
  end

  private

  # The envelope is newline-delimited; its first line is a JSON header carrying
  # the DSN the event was meant for. Accept only envelopes addressed to our own
  # GlitchTip DSN (same host and project id), so the tunnel cannot be used to
  # relay to an arbitrary Sentry server.
  sig { params(envelope: String).returns(T::Boolean) }
  def matches_our_dsn?(envelope)
    incoming = incoming_dsn(envelope)
    return false if incoming.nil?

    ErrorTracking.own_project?(incoming)
  end

  # The header's DSN, or nil if the envelope has no parseable header, no dsn, or
  # a malformed dsn. All "cannot extract a usable DSN" cases collapse to nil here
  # so matches_our_dsn? only ever compares a well-formed DSN.
  sig { params(envelope: String).returns(T.nilable(GlitchTipDsn)) }
  def incoming_dsn(envelope)
    dsn = envelope_header_dsn(envelope)
    dsn.present? ? GlitchTipDsn.new(dsn) : nil
  rescue GlitchTipDsn::InvalidDsn
    nil
  end

  # The "dsn" field of the envelope's first line (a JSON header), or nil if that
  # line is absent or is not JSON.
  sig { params(envelope: String).returns(T.nilable(String)) }
  def envelope_header_dsn(envelope)
    header_line = envelope.split("\n", 2).first
    return nil if header_line.blank?

    JSON.parse(header_line)["dsn"]
  rescue JSON::ParserError
    nil
  end
end
