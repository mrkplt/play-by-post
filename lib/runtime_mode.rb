# typed: true
# frozen_string_literal: true

# Which slice of the app this process serves, read from RUNTIME_MODE.
#
# One image, three modes, off one env var — so a dedicated API-only process can
# run the same container on an `api.*` hostname that bypasses the Cloudflare
# proxy, while the default all-in-one process keeps serving everything.
#
#   unset  → ALL     draw every route (today's behaviour, unchanged)
#   "web"  → WEB     draw the web (session/Devise) routes only
#   "api"  → API     draw the /api + machine-auth + shared-infra routes only
#
# The gate is at ROUTE-DRAWING (config/routes.rb), not controller load: with
# `config.eager_load = true` every controller loads regardless of routes, and a
# loaded-but-unrouted controller is harmless. The *undrawn route* is the
# boundary. routes.rb reads the mode ONLY through this module — no scattered
# ENV["RUNTIME_MODE"] string comparisons.
#
# A pure, memo-free reader (like Branding) so specs can stub ENV per-example
# with no cached value leaking across them. Reads a plain ENV var only — it
# touches no credentials or Active Storage, so it is safe at route-draw time and
# during the credential-less `assets:precompile` build.
module RuntimeMode
  extend T::Sig

  ENV_VAR = "RUNTIME_MODE"
  WEB = "web"
  API = "api"

  # The raw configured value, blank-normalised to nil (unset == "" == all).
  sig { returns(T.nilable(String)) }
  def self.value
    ENV[ENV_VAR].presence
  end

  # Draw the web (session/Devise) routes? True when unset or explicitly "web".
  sig { returns(T::Boolean) }
  def self.web?
    value.nil? || value == WEB
  end

  # Draw the /api namespace routes? True when unset or explicitly "api".
  sig { returns(T::Boolean) }
  def self.api?
    value.nil? || value == API
  end

  # No mode set — draw everything (the default, all-in-one process).
  sig { returns(T::Boolean) }
  def self.all?
    value.nil?
  end
end
