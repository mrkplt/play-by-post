# typed: true

# Deletes expired game-export archives.
#
# Export download URLs are signed for 7 days (see ExportJob); nothing consumes
# an archive after that, so the objects would otherwise accumulate in storage
# forever. This job runs daily (config/recurring.yml) and destroys export
# requests older than the retention window, which purges their attached archive
# blob from storage (R2) along with the record.
class ExportCleanupJob < ApplicationJob
  extend T::Sig

  queue_as :default

  RETENTION = T.let(7.days, ActiveSupport::Duration)

  sig { void }
  def perform
    # Destroying the request purges its attached archive: has_one_attached
    # defaults to dependent: :purge_later, which enqueues the blob deletion.
    GameExportRequest.where(created_at: ..RETENTION.ago).find_each(&:destroy)
  end
end
