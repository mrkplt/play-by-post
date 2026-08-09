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

    scene_ids = Scene.where(game_id: game.id).pluck(:id)
    post_ids = Post.where(scene_id: scene_ids).pluck(:id)
    character_ids = Character.where(game_id: game.id).pluck(:id)

    purge_artifacts(game, scene_ids, post_ids)
    delete_records(game, scene_ids, post_ids, character_ids)
  end

  private

  # Collect and remove every stored artifact tied to the game — post images,
  # scene images, uploaded game files, and export archives — deleting each from
  # storage now (purge, not purge_later) so nothing is left orphaned in R2.
  # ActiveStorage::Attached::One#purge is a no-op when nothing is attached.
  sig { params(game: Game, scene_ids: T::Array[Integer], post_ids: T::Array[Integer]).void }
  def purge_artifacts(game, scene_ids, post_ids)
    Post.where(id: post_ids).with_attached_image.find_each { |post| post.image.purge }
    Scene.where(id: scene_ids).with_attached_image.find_each { |scene| scene.image.purge }
    GameFile.where(game_id: game.id).with_attached_file.find_each { |game_file| game_file.file.purge }
    GameExportRequest.where(game_id: game.id).with_attached_archive.find_each { |request| request.archive.purge }
  end

  # Delete every record belonging to the game, children before parents so no
  # foreign key is violated, in batches to bound memory. Attachments are already
  # gone, so these are plain deletes — no cascade, no callbacks. Scenes' self
  # reference (parent_scene_id) is broken first so the bulk delete is FK-safe.
  sig do
    params(
      game: Game,
      scene_ids: T::Array[Integer],
      post_ids: T::Array[Integer],
      character_ids: T::Array[Integer]
    ).void
  end
  def delete_records(game, scene_ids, post_ids, character_ids)
    ActiveRecord::Base.transaction do
      PostRead.where(post_id: post_ids).in_batches.delete_all
      Post.where(id: post_ids).in_batches.delete_all
      SceneParticipant.where(scene_id: scene_ids).in_batches.delete_all
      SceneSummary.where(scene_id: scene_ids).in_batches.delete_all
      NotificationPreference.where(scene_id: scene_ids).in_batches.delete_all
      Scene.where(id: scene_ids).update_all(parent_scene_id: nil)
      Scene.where(id: scene_ids).in_batches.delete_all
      CharacterVersion.where(character_id: character_ids).in_batches.delete_all
      Character.where(id: character_ids).in_batches.delete_all
      GameFile.where(game_id: game.id).in_batches.delete_all
      # NotebookEntry may reference a Page via promoted_page_id, so it is
      # deleted before Page.
      NotebookEntry.where(game_id: game.id).in_batches.delete_all
      Page.where(game_id: game.id).in_batches.delete_all
      GameLink.where(game_id: game.id).in_batches.delete_all
      Invitation.where(game_id: game.id).in_batches.delete_all
      GameMember.where(game_id: game.id).in_batches.delete_all
      GameExportRequest.where(game_id: game.id).in_batches.delete_all
      game.delete
    end
  end
end
