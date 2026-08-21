# typed: true

class UserProfile < ApplicationRecord
  extend T::Sig

  belongs_to :user

  # The per-user AI DISPLAY preference (AI Control Plane): independent of
  # ai_summaries_consent (producing) — this is about consuming. shown = AI
  # asset renders normally, no loud badge (provenance still recorded); tagged
  # = renders with a prominent "AI-generated" badge; hidden = AI-generated
  # rows are filtered out of this viewer's index/scene view/RSS entirely. See
  # SceneSummary.visible_to and SceneSummaryPresenter#show_ai_badge?.
  enum :ai_display_preference, { shown: 0, tagged: 1, hidden: 2 }, default: :tagged

  validates :display_name, length: { maximum: 100 }, allow_blank: true

  sig { returns(T::Boolean) }
  def display_name_set?
    display_name.present?
  end

  # Assigns and persists a new display name in one call, so
  # ProfilesController#update only has to ask "did it save," not carry the two
  # separate statements that made up the assignment.
  sig { params(new_display_name: T.untyped).returns(T::Boolean) }
  def update_display_name(new_display_name)
    self.display_name = new_display_name
    save
  end
end
