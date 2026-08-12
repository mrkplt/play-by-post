# typed: false

# Cloudflare Turnstile config. Keys resolve credential → ENV → Cloudflare's
# always-pass test keys, so dev/test and the credential-less precompile build
# need no real secrets. Real keys must be set in production. See docs/CONFIGURATION.md.
module Turnstile
  TEST_SITE_KEY = "1x00000000000000000000AA"
  TEST_SECRET_KEY = "1x0000000000000000000000000000000AA"

  SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  SCRIPT_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js"

  module_function

  def credentials
    # Skip the (empty) credential read during the SECRET_KEY_BASE_DUMMY precompile build.
    return {} if ENV["SECRET_KEY_BASE_DUMMY"]

    Rails.application.credentials.turnstile || {}
  end

  def site_key
    credentials[:site_key].presence || ENV["TURNSTILE_SITE_KEY"].presence || TEST_SITE_KEY
  end

  def secret_key
    credentials[:secret_key].presence || ENV["TURNSTILE_SECRET_KEY"].presence || TEST_SECRET_KEY
  end

  # Off in test so unrelated form specs need no token; specs opt in by stubbing this.
  def enabled?
    !Rails.env.test?
  end
end
