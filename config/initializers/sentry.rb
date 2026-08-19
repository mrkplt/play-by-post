# typed: true

# Backend error tracking, reported to GlitchTip (self-hosted, Sentry-protocol
# compatible) via the Ruby SDK. Sentry.init must run at initializer time to
# install its Rack middleware, which is *before* the app autoloader is active —
# so the DSN is resolved inline here rather than through the ErrorTracking app
# model (referencing an autoloaded constant here raises NameError at boot).
#
# ErrorTracking (app/models/error_tracking.rb) resolves the DSN identically and
# is the source of truth for the post-boot surfaces (the browser SDK tunnel and
# the layout); keep the two resolutions in step. Only initialize when a DSN is
# set, so local development and CI run without one.
dsn = Rails.application.credentials.glitchtip&.dsn || ENV["GLITCHTIP_DSN"]

if dsn.present?
  Sentry.init do |config|
    config.dsn = dsn
    config.traces_sample_rate = 0.1 # 10% of transactions
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  end
end
