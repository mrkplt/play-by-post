# typed: true

# Error tracking, reported to GlitchTip (self-hosted, Sentry-protocol
# compatible) via the Sentry SDK. Only initialize when a DSN is configured,
# so local development and CI run without one.
dsn = Rails.application.credentials.glitchtip_dsn || ENV["GLITCHTIP_DSN"]

if dsn.present?
  Sentry.init do |config|
    config.dsn = dsn
    config.breadcrumbs_logger = [ :active_support_logger ]
  end
end
