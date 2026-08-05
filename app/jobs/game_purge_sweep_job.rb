# typed: true

# Scans for games that have been soft-deleted long enough and enqueues a
# GamePurgeJob to destroy each one.
#
# Deletion is two-phase (see REQUIREMENTS "Game Deletion"): the GM soft-deletes
# a game (sets deleted_at), which hides it immediately, and this sweep — run
# daily (config/recurring.yml) — hands each game past the retention window to a
# per-game purge job that does the actual artifact removal. Splitting the sweep
# from the purge keeps each purge (which cascades scenes, posts, characters,
# files and their attachments) isolated and independently retryable.
class GamePurgeSweepJob < ApplicationJob
  extend T::Sig

  queue_as :default

  # How long a soft-deleted game lingers before it is purged. The window is a
  # safety buffer against an accidental deletion reaching permanent removal.
  RETENTION = T.let(7.days, ActiveSupport::Duration)

  sig { void }
  def perform
    purgeable.find_each { |game| GamePurgeJob.perform_later(game.id) }
  end

  # Soft-deleted games whose retention window has elapsed. `unscoped` bypasses
  # the model's default scope (which hides all deleted games); the range bound
  # is `<=`, and NULL deleted_at (a live game) never satisfies it, so only games
  # deleted at or before the cutoff are returned.
  sig { returns(ActiveRecord::Relation) }
  def purgeable
    Game.unscoped.where(deleted_at: ..RETENTION.ago)
  end
end
