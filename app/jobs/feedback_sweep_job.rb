# typed: true

# Sweeps user feedback/recommendations into the Fizzy board, one card per entry.
#
# Runs hourly (config/recurring.yml). Every entry with a NULL swept_at gets a
# card created in the personal Fizzy instance — new API cards land in the
# "Maybe?" column — and is then stamped with swept_at. Entries whose card
# creation fails keep their NULL swept_at so the next hourly run retries them.
class FeedbackSweepJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { void }
  def perform
    unswept.find_each { |feedback| sweep(feedback) }
  rescue FizzySweepService::ConfigurationError => e
    # Missing credentials are not going to fix themselves mid-run; log once
    # and let the next hourly schedule attempt again.
    Rails.logger.error("FeedbackSweepJob: #{e.message}")
  end

  # Unimported entries — those not yet swept into Fizzy.
  sig { returns(ActiveRecord::Relation) }
  def unswept
    Feedback.unswept
  end

  private

  sig { params(feedback: Feedback).void }
  def sweep(feedback)
    FizzySweepService.new.create_card(feedback)
    feedback.update!(swept_at: Time.current)
  rescue FizzySweepService::ConfigurationError
    raise
  rescue StandardError => e
    # Isolated failure: leave swept_at NULL so this entry is retried on the
    # next run instead of blocking the rest of the sweep.
    Rails.logger.error("FeedbackSweepJob: failed to sweep feedback ##{feedback.id}: #{e.message}")
  end
end
