# typed: true

class UserProfile < ApplicationRecord
  extend T::Sig

  belongs_to :user

  # The per-user AI DISPLAY preference (AI Control Plane): the sole per-user AI
  # control — this is about consuming, not producing (production is the GM's
  # game-level Game#ai_summaries_enabled). shown = AI asset renders normally, no
  # loud badge (provenance still recorded); tagged = renders with a prominent
  # "AI-generated" badge; hidden = AI-generated rows are filtered out of this
  # viewer's index/scene view/RSS entirely, so it doubles as the viewer's opt-out
  # of seeing AI content. See SceneSummary.visible_to and
  # SceneSummaryPresenter#show_ai_badge?.
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
