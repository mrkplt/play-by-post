# typed: false

require "rails_helper"

# Routes are drawn once at boot, so the effect of RUNTIME_MODE on the drawn
# route set can only be observed for the value present at boot (unset in test —
# both surfaces are drawn). These specs pin two things that DON'T need a re-draw:
#
#   1. In the boot (unset) mode both surfaces are present — the default draws
#      everything, unchanged from before the split.
#   2. config/routes.rb gates the two surfaces THROUGH RuntimeMode — the undrawn
#      route is the boundary, so if either guard is deleted the gate is gone.
#      RuntimeMode itself is exhaustively unit-tested (spec/lib/runtime_mode_spec.rb)
#      for all three env values; this asserts routes.rb actually consults it.
RSpec.describe "RUNTIME_MODE route gating" do
  describe "the default (unset) boot draws every surface" do
    subject(:route_names) { Rails.application.routes.routes.map(&:name).compact }

    it "draws the web session surface" do
      expect(route_names).to include("new_user_session")
    end

    it "draws the web root and game surface" do
      expect(route_names).to include("root", "games")
    end

    it "draws the /api data surface" do
      expect(route_names).to include("api_pages", "api_notebook_entries")
    end

    it "draws the machine-auth and shared-infra surface" do
      expect(route_names).to include(
        "rails_health_check",
        "rails_resend_inbound_emails",
        "deploy_webhook"
      )
    end
  end

  describe "config/routes.rb wires the surfaces through RuntimeMode" do
    subject(:source) { File.read(Rails.root.join("config/routes.rb")) }

    it "gates the web surface on RuntimeMode.web?" do
      expect(source).to include("RuntimeMode.web?")
    end

    it "gates the /api surface on RuntimeMode.api?" do
      expect(source).to include("RuntimeMode.api?")
    end
  end
end
