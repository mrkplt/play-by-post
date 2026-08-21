# typed: strict

class Shared::SceneSummaryComponent < ApplicationComponent
  extend T::Sig

  sig { params(summary: SceneSummaryPresenter).void }
  def initialize(summary:)
    @summary = summary
  end

  sig { returns(String) }
  def status_badge_variant
    case @summary.status_label
    when "AI-generated" then "blue"
    when "Edited" then "yellow"
    else "gray"
    end
  end

  # The AI Control Plane's per-viewer DISPLAY preference: the viewer's
  # "shown" preference suppresses the prominent "AI-generated" badge
  # (provenance is still recorded and still shown via the "Generated <date>"
  # meta line below). "Edited"/"Hand-written" are unaffected — those already
  # disclose human involvement and are not the loud AI badge this preference
  # governs.
  sig { returns(T::Boolean) }
  def show_status_badge?
    @summary.status_label != "AI-generated" || @summary.show_ai_badge?
  end

  sig { returns(T::Boolean) }
  def can_manage?
    @summary.can_manage?
  end

  # This summary is an unpublished draft — drives the draft badge and the
  # Publish affordance, both GM-only.
  sig { returns(T::Boolean) }
  def draft?
    @summary.draft?
  end

  sig { returns(String) }
  def publish_path
    @summary.routes.publish_path
  end
end
