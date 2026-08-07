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

  # Imports this entry into the Fizzy board and stamps swept_at. A failing card
  # creation leaves swept_at NULL so the hourly job retries the entry; missing
  # Fizzy credentials are re-raised so the job can log them once per run.
  sig { void }
  def sweep
    FizzySweepService.create_card(self)
    update!(swept_at: Time.current)
  rescue FizzySweepService::ConfigurationError
    raise
  rescue StandardError => e
    Rails.logger.error("Feedback ##{id} failed to sweep into Fizzy: #{e.message}")
  end
end
