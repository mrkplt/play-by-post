# typed: true

# Permanently removes a single soft-deleted game and everything attached to it.
#
# Destroying the game cascades (dependent: :destroy) to its scenes, posts,
# characters, character versions, game files, invitations, memberships, and
# export requests; each attachment (post images, scene images, game files,
# export archives) is purged from storage because has_one_attached defaults to
# dependent: :purge_later. Enqueued per game by GamePurgeSweepJob.
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

    game.destroy!
  end
end
