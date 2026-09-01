# typed: true

# Names an export's target: the single requested game, or "all games" when
# none was requested. Owns the game-or-not branching that used to be repeated
# across the job's filename, scope-label, and mail steps.
class ExportTarget
  extend T::Sig

  sig { params(game: T.nilable(Game)).void }
  def initialize(game)
    @game = game
  end

  # Attaches the freshly built zip to the request's archive, under this
  # target's filename and scope label. `archive` is the open, rewound Tempfile
  # GameExportService produced — streamed straight to storage, never read into
  # a String.
  sig { params(request: GameExportRequest, archive: T.untyped, user: User).void }
  def attach(request:, archive:, user:)
    filename = archive_filename
    archive.rewind

    AttachmentUploader.attach(
      attachment: request.archive,
      attachable: { io: archive, filename: filename, content_type: "application/zip" },
      context: AttachmentUploader::Context.build(
        kind: "export",
        owner: AttachmentUploader::Owner.build(user: user, game: @game),
        naming: AttachmentUploader::Naming.build(original_filename: filename, export_scope: scope_label)
      )
    )
  end

  private

  sig { returns(String) }
  def scope_label
    @game ? @game.name : "all-games"
  end

  sig { returns(String) }
  def archive_filename
    "#{filename_prefix}-export-#{Time.current.utc.strftime('%Y-%m-%d')}.zip"
  end

  # By the time this runs, every run of whitespace has already become a single
  # "-", so a trailing `.strip` here would never have anything to trim — the
  # slug can still end up with leading/trailing dashes (e.g. " Foo " ->
  # "-foo-"), which is accepted as a harmless filename character.
  sig { returns(String) }
  def filename_prefix
    return "all-games" unless @game

    @game.name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").gsub(/-+/, "-")
  end
end

class ExportJob < ApplicationJob
  extend T::Sig

  queue_as :default

  # Which games the export covers: the one requested, or every game the user is
  # still associated with (banned memberships drop out entirely). Isolated so the
  # selection can be asserted without persisting a membership per case.
  sig { params(user: User, game: T.nilable(Game)).returns(T::Array[Game]) }
  def games_for(user, game)
    return [ game ] if game

    user.game_members
        .where(status: %w[active removed])
        .where.not(status: "banned")
        .includes(:game)
        .filter_map(&:game)
  end

  sig { params(request_id: Integer).void }
  def perform(request_id)
    process(find_request(request_id))
  rescue StandardError => error
    handle_failure(request_id, error)
    raise
  end

  private

  sig { params(request_id: Integer).returns(T.nilable(GameExportRequest)) }
  def find_request(request_id)
    GameExportRequest.find_by(id: request_id)
  end

  sig { params(request: T.nilable(GameExportRequest)).void }
  def process(request)
    return unless request

    user = T.must(request.user)
    build_archive(request, user, request.game)
    finish!(request)
  end

  # Record the receipt only after a successful attach: this is what gates
  # resend-vs-reprocess and drives the "last export" display. A failed export
  # leaves succeeded_at nil, so it never blocks a retry.
  sig { params(request: GameExportRequest).void }
  def finish!(request)
    request.mark_succeeded!
    ExportDelivery.email_download_link(request)
  end

  sig { params(request: GameExportRequest, user: User, game: T.nilable(Game)).void }
  def build_archive(request, user, game)
    archive = GameExportService.new(user, games_for(user, game)).call
    begin
      ExportTarget.new(game).attach(request:, archive:, user:)
    ensure
      archive.close
      archive.unlink
    end
  end

  sig { params(request_id: Integer, error: StandardError).void }
  def handle_failure(request_id, error)
    Rails.logger.error("ExportJob failed for request #{request_id}: #{error.message}")
    failed_request = find_request(request_id)
    failed_user = failed_request&.user
    return unless failed_user

    T.unsafe(ExportMailer).export_failed(failed_user, game: failed_request.game).deliver_later
  end
end
