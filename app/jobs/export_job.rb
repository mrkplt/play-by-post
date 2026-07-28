# typed: true

class ExportJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(request_id: Integer).void }
  def perform(request_id)
    request = GameExportRequest.find_by(id: request_id)
    return unless request

    user = T.must(request.user)
    game = request.game

    games = if game
      [ game ]
    else
      user.game_members
          .where(status: %w[active removed])
          .where.not(status: "banned")
          .includes(:game)
          .filter_map(&:game)
    end

    zip_data = GameExportService.new(user, games).call
    filename = archive_filename(game)

    request.archive.attach(
      io: StringIO.new(zip_data),
      filename: filename,
      content_type: "application/zip"
    )

    download_url = request.archive.blob.url(
      expires_in: 7.days,
      disposition: :attachment
    )

    T.unsafe(ExportMailer).export_ready(user, download_url: download_url, game: game).deliver_later
  rescue StandardError => e
    Rails.logger.error("ExportJob failed for request #{request_id}: #{e.message}")
    failed_request = GameExportRequest.find_by(id: request_id)
    failed_user = failed_request&.user
    T.unsafe(ExportMailer).export_failed(failed_user, game: failed_request.game).deliver_later if failed_user
    raise
  end

  private

  sig { params(game: T.nilable(Game)).returns(String) }
  def archive_filename(game)
    date = Time.current.utc.strftime("%Y-%m-%d")
    if game
      slug = game.name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").gsub(/-+/, "-").strip
      "#{slug}-export-#{date}.zip"
    else
      "all-games-export-#{date}.zip"
    end
  end
end
