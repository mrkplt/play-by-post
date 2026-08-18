# typed: true

# Permanently removes a single soft-deleted game and everything attached to it.
#
# Rather than leaning on association cascades (dependent: :destroy) and Active
# Storage's fire-and-forget purge_later, this job collects the game's artifacts
# and records and deletes them explicitly: every stored blob is purged from
# storage in the job, and every dependent row is deleted child-first, in
# batches, so the removal is bounded, ordered, and completes within the run.
# Enqueued per game by GamePurgeSweepJob.
class GamePurgeJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(game_id: Integer).void }
  def perform(game_id)
    # `unscoped` so the soft-deleted game is visible past the default scope.
    game = Game.unscoped.find_by(id: game_id)

    # Guard against a race or a game that is no longer eligible: only purge a
    # game that is still soft-deleted.
    return unless game&.deleted?

    scope = GamePurgeScope.for(game)
    purge_artifacts(scope)
    delete_records(scope)
  end

  private

  # Collect and remove every stored artifact tied to the game — uploaded game
  # files and export archives — deleting each from storage now (purge, not
  # purge_later) so nothing is left orphaned in R2.
  # ActiveStorage::Attached::One#purge is a no-op when nothing is attached.
  sig { params(scope: GamePurgeScope).void }
  def purge_artifacts(scope)
    purge_game_files(scope)
  end

  sig { params(scope: GamePurgeScope).void }
  def purge_game_files(scope)
    game_id = scope.game_id
    GameFile.where(game_id: game_id).with_attached_file.find_each { |game_file| game_file.file.purge }
    GameExportRequest.where(game_id: game_id).with_attached_archive.find_each { |request| request.archive.purge }
  end

  # Deletion order (children before parents, no cascade/callbacks) is owned by
  # GamePurgeScope; the job's job is only to wrap it in a transaction.
  sig { params(scope: GamePurgeScope).void }
  def delete_records(scope)
    ActiveRecord::Base.transaction { scope.delete_all_dependents! }
  end
end
