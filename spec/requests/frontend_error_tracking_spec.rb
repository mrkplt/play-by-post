require "rails_helper"

# The browser error-tracking SDK is booted from the application layout, gated on
# a configured DSN. It reports through the same-origin tunnel, so the DSN's own
# host is never contacted from the browser. Rendered on a real page so the gating
# and the actual markup are exercised.
RSpec.describe "Frontend error tracking (GlitchTip)", type: :request do
  let(:user) { create(:user, :with_profile) }

  before { sign_in(user) }

  context "when a GlitchTip DSN is configured" do
    before do
      allow(ErrorTracking).to receive(:enabled?).and_return(true)
      allow(ErrorTracking).to receive(:dsn).and_return("https://pub@glitchtip.internal/42")
    end

    it "loads the Sentry browser bundle before the app importmap" do
      get root_path

      loader_at = response.body.index("browser.sentry-cdn.com")
      importmap_at = response.body.index("importmap")
      expect(loader_at).not_to be_nil
      expect(loader_at).to be < importmap_at
    end

    it "initialises the SDK with the DSN and the same-origin tunnel path" do
      get root_path

      expect(response.body).to include("https://pub@glitchtip.internal/42")
      expect(response.body).to include(%(tunnel: "#{error_tunnel_path}"))
    end
  end

  context "when no GlitchTip DSN is configured" do
    before { allow(ErrorTracking).to receive(:enabled?).and_return(false) }

    it "loads no SDK and leaks no DSN into the page" do
      get root_path

      expect(response.body).not_to include("browser.sentry-cdn.com")
      expect(response.body).not_to include("glitchtip.internal")
    end
  end
end
