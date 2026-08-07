# typed: true

# A free-form feedback report submitted from the nav-drawer feedback modal.
# Records who submitted it (`user`) and the page URL they were on (`url`) when
# they opened the modal.
class Feedback < ApplicationRecord
  extend T::Sig

  belongs_to :user

  validates :body, presence: true

  # Entries not yet imported into the Fizzy board (FeedbackSweepJob).
  sig { returns(ActiveRecord::Relation) }
  def self.unswept
    where(swept_at: nil)
  end
end
