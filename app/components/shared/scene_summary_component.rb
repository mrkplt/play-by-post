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
