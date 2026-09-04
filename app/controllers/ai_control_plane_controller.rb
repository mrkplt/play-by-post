# typed: true

# The AI Control Plane explainer page (Fizzy #113): a single read-only screen
# describing how AI works in the app — BYOK custody, key resolution, the two
# consent gates, the display preference, and provenance. Linked from the AI
# settings surfaces (Profile, Game Settings, the BYOK key form). No model state;
# the whole page is Shared::AiControlPlaneExplainerComponent.
class AiControlPlaneController < ApplicationController
  # Static editorial content with no resource to authorize — any signed-in user
  # may read it (the route already sits inside `authenticate :user`). Skip the
  # Pundit net for show (allowlisted in bin/check-authorization).
  after_action :verify_authorized
  skip_after_action :verify_authorized, only: :show

  def show
  end
end
