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
end
