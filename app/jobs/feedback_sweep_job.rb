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
    Feedback.unswept.find_each(&:sweep)
  rescue FizzySweepService::ConfigurationError => error
    # Missing credentials are not going to fix themselves mid-run; log once
    # and let the next hourly schedule attempt again.
    Rails.logger.error("FeedbackSweepJob: #{error.message}")
  end
end
