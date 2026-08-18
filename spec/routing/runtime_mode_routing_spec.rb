# typed: false

require "rails_helper"

# The RUNTIME_MODE route boundary, verified by actually re-drawing the routes
# under each mode. Routes are drawn once at boot (unset in test), so to observe
# the api/web boundary we stub RuntimeMode and reload the route set inside the
# example — then restore the real routes in an ensure so nothing leaks into
# another spec (a leaked route table has broken dozens of specs before; see
# CLAUDE.md testing notes).
#
# The boundary under test: `api` mode draws ONLY the JSON /api namespace (the
# Cloudflare-bypassing bearer-token data API); everything else — mail ingress,
# deploy relay, RSS feed, Swagger docs, the whole Devise/game surface — is web;
# only the /up health check is shared.
RSpec.describe "RUNTIME_MODE route gating" do
  # Route names present when the app is drawn with the given RuntimeMode answers.
  # Draw the routes with RUNTIME_MODE set to `mode` (nil = unset) and return the
  # drawn route names. Driving the real env var (not a stub on RuntimeMode) means
  # the ensure just restores the env and re-draws with the true value, so the
  # stubbed route table never leaks into another spec.
  def route_names_for(mode)
    original = ENV.fetch("RUNTIME_MODE", nil)
    mode.nil? ? ENV.delete("RUNTIME_MODE") : ENV["RUNTIME_MODE"] = mode
    Rails.application.reload_routes!
    Rails.application.routes.routes.map(&:name).compact
  ensure
    original.nil? ? ENV.delete("RUNTIME_MODE") : ENV["RUNTIME_MODE"] = original
    Rails.application.reload_routes!
  end

  # The JSON data API — the only thing an api-mode process draws.
  API_ROUTES = %w[api_pages api_notebook_entries].freeze
  # Web surface: session, game surface, and the machine-auth/webhook/docs routes
  # that are NOT the JSON data API.
  WEB_ROUTES = %w[
    new_user_session root games
    rails_resend_inbound_emails deploy_webhook rss_feed
  ].freeze
  # Drawn in every mode.
  SHARED_ROUTES = %w[rails_health_check].freeze

  describe "unset (default) draws every surface" do
    subject(:names) { route_names_for(nil) }

    it { is_expected.to include(*API_ROUTES) }
    it { is_expected.to include(*WEB_ROUTES) }
    it { is_expected.to include(*SHARED_ROUTES) }
  end

  describe "api mode draws only the JSON /api namespace (plus shared)" do
    subject(:names) { route_names_for("api") }

    it "draws the JSON data API" do
      expect(names).to include(*API_ROUTES)
    end

    it "draws the shared health check" do
      expect(names).to include(*SHARED_ROUTES)
    end

    it "draws none of the web surface — not even the machine-auth/webhook routes" do
      expect(names).not_to include(*WEB_ROUTES)
    end
  end

  describe "web mode draws everything but the JSON /api namespace (plus shared)" do
    subject(:names) { route_names_for("web") }

    it "draws the full web surface, including mail ingress, deploy relay and RSS" do
      expect(names).to include(*WEB_ROUTES)
    end

    it "draws the shared health check" do
      expect(names).to include(*SHARED_ROUTES)
    end

    it "draws none of the JSON data API" do
      expect(names).not_to include(*API_ROUTES)
    end
  end
end
