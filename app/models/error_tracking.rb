# typed: strict

# Single source of truth for the GlitchTip DSN, read by every surface that
# reports errors: the backend Ruby SDK (config/initializers/sentry.rb), the
# browser SDK tunnel (ErrorTunnelController / ErrorEnvelopeForwardJob), and the
# layout that boots the browser SDK. Resolution matches every other secret here
# — the glitchtip credential wins, then the GLITCHTIP_DSN env var — and is nil
# when neither is set, which disables error reporting on all surfaces at once.
#
# A pure, memo-free reader (like Branding) so specs can stub the DSN per-example
# without a cached value leaking across them.
module ErrorTracking
  extend T::Sig

  # The raw DSN string, or nil when error tracking is unconfigured.
  sig { returns(T.nilable(String)) }
  def self.dsn
    Rails.application.credentials.glitchtip&.dsn || ENV["GLITCHTIP_DSN"]
  end

  # True when a DSN is configured, i.e. error reporting is enabled.
  sig { returns(T::Boolean) }
  def self.enabled?
    dsn.present?
  end

  # The parsed DSN, or nil when unconfigured. Raises GlitchTipDsn::InvalidDsn
  # only for a configured-but-malformed DSN — a deployment misconfiguration
  # worth surfacing loudly rather than swallowing.
  sig { returns(T.nilable(GlitchTipDsn)) }
  def self.parsed_dsn
    value = dsn
    value.present? ? GlitchTipDsn.new(value) : nil
  end

  # Whether an incoming DSN addresses our configured GlitchTip project. False
  # when tracking is unconfigured, so the tunnel drops everything in that case.
  sig { params(other: GlitchTipDsn).returns(T::Boolean) }
  def self.own_project?(other)
    !!parsed_dsn&.same_project?(other)
  end
end
