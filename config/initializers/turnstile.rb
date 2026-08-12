# typed: false

# Cloudflare Turnstile configuration — bot detection on public/write forms
# (magic-link sign-in, feedback modal). See docs/CONFIGURATION.md.
#
# Two keys: a public *site key* embedded in the widget HTML, and a secret
# *secret key* used server-side by TurnstileVerifier against the siteverify API.
#
# Resolution order for each, matching the repo's `credential || ENV` convention
# (see config/storage.yml): encrypted credential → environment variable →
# Cloudflare's well-known **test keys**, which always pass. The test-key default
# means dev and test — and the credential-less `assets:precompile` build — work
# with no real secrets configured. Real keys MUST be provisioned in production
# credentials before this reaches users, or the widget renders with the
# always-pass test key and provides no protection.
#
# Credential shape (bin/rails credentials:edit --environment production):
#   turnstile:
#     site_key: "0x4AAAAAAA..."     # public, safe to embed
#     secret_key: "0x4AAAAAAA..."   # secret — siteverify only
module Turnstile
  # Cloudflare's documented always-pass test keys.
  # https://developers.cloudflare.com/turnstile/troubleshooting/testing/
  TEST_SITE_KEY = "1x00000000000000000000AA"
  TEST_SECRET_KEY = "1x0000000000000000000000000000000AA"

  SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  SCRIPT_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js"

  module_function

  # During the credential-less Docker asset-precompile build, skip reading
  # credentials (which would be empty anyway) and use the test key.
  def credentials
    return {} if ENV["SECRET_KEY_BASE_DUMMY"]

    Rails.application.credentials.turnstile || {}
  end

  def site_key
    credentials[:site_key].presence || ENV["TURNSTILE_SITE_KEY"].presence || TEST_SITE_KEY
  end

  def secret_key
    credentials[:secret_key].presence || ENV["TURNSTILE_SECRET_KEY"].presence || TEST_SECRET_KEY
  end

  # Turnstile is skipped entirely in the test environment so unrelated form
  # specs (and the dev quick-login forms) don't have to satisfy a token. It can
  # be force-enabled in a spec by stubbing `Turnstile.enabled?` to true.
  def enabled?
    !Rails.env.test?
  end
end
