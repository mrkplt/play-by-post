# typed: true

# A parsed GlitchTip/Sentry DSN.
#
# A DSN has the shape https://<public_key>@<host>[:port]/<project_id>. The
# browser SDK tunnel (see ErrorTunnelController) needs three things off it: the
# host and project id an incoming envelope must match (so the public tunnel
# cannot be turned into an open relay), and the ingest URL to forward a matched
# envelope to. GlitchTip speaks the Sentry envelope protocol, so the ingest path
# is the standard /api/<project_id>/envelope/.
#
# The self-hosted GlitchTip has no public ingress; forwarding runs from inside
# the app, which reaches it over the internal backplane.
class GlitchTipDsn
  extend T::Sig

  class InvalidDsn < StandardError; end

  sig { params(dsn: String).void }
  def initialize(dsn)
    @uri = T.let(parse(dsn), URI::Generic)
  end

  # The DSN host — an envelope's DSN host must equal this to be forwarded.
  sig { returns(String) }
  def host
    T.must(@uri.host)
  end

  # The project id — the DSN path with its leading slash removed. An envelope's
  # DSN project id must equal this to be forwarded.
  sig { returns(String) }
  def project_id
    # A parsed URI with a host always has a (possibly empty) path string.
    id = T.must(@uri.path).delete_prefix("/")
    raise InvalidDsn, "DSN has no project id" if id.empty?

    id
  end

  # The Sentry-protocol envelope ingest URL events are forwarded to, on the same
  # scheme/host/port as the DSN — the public key (and any legacy secret) dropped.
  sig { returns(String) }
  def envelope_url
    uri_port = @uri.port
    port = uri_port == @uri.default_port ? "" : ":#{uri_port}"
    "#{@uri.scheme}://#{host}#{port}/api/#{project_id}/envelope/"
  end

  # Whether another DSN addresses the same GlitchTip project — same host and
  # project id. The tunnel uses this to accept only envelopes meant for us.
  sig { params(other: GlitchTipDsn).returns(T::Boolean) }
  def same_project?(other)
    host == other.host && project_id == other.project_id
  end

  private

  sig { params(dsn: String).returns(URI::Generic) }
  def parse(dsn)
    uri = URI.parse(dsn)
    raise InvalidDsn, "DSN has no host" if uri.host.nil?

    uri
  rescue URI::InvalidURIError => error
    raise InvalidDsn, error.message
  end
end
