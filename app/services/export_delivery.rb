# typed: true

# Emails the download link for a completed export request. Shared by ExportJob
# (after processing a fresh export) and GameExportsController (when resending an
# existing valid receipt), so the signed-URL lifetime and mailer call live in
# one place.
class ExportDelivery
  extend T::Sig

  DOWNLOAD_EXPIRY = T.let(7.days, ActiveSupport::Duration)

  sig { params(request: GameExportRequest).void }
  def self.email_download_link(request)
    user = T.must(request.user)
    download_url = download_url_for(request)

    T.unsafe(ExportMailer).export_ready(user, download_url: download_url, game: request.game).deliver_later
  end

  # Generates the signed download URL. Active Storage's Disk service needs
  # url_options (host) to build an absolute URL; the S3/R2 service ignores them.
  # Use the app's configured mailer host so this works from a job or a request.
  sig { params(request: GameExportRequest).returns(String) }
  def self.download_url_for(request)
    ActiveStorage::Current.url_options ||= Rails.application.config.action_mailer.default_url_options
    request.archive.blob.url(expires_in: DOWNLOAD_EXPIRY, disposition: :attachment)
  end
end
