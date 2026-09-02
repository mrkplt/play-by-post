# typed: true

# Deletes every record belonging to a game, children before parents so no
# foreign key is violated, in batches to bound memory. Attachments are already
# purged by the caller, so these are plain deletes — no cascade, no callbacks.
# The id sets it operates over come from a GamePurgeScope; this class owns only
# the deletion order.
class GamePurgeDeletion
  extend T::Sig

  sig { params(scope: GamePurgeScope).void }
  def initialize(scope)
    @scope = scope
  end

  sig { void }
  def delete_all!
    delete_posts_and_reads
    delete_scenes_and_children
    delete_characters_and_versions
    delete_game_owned_records
    @scope.game.delete
  end

  private

  sig { returns(Integer) }
  def game_id = @scope.game_id

  sig { returns(T::Array[Integer]) }
  def scene_ids = @scope.scene_ids

  sig { void }
  def delete_posts_and_reads
    post_ids = @scope.post_ids
    PostRead.where(post_id: post_ids).in_batches.delete_all
    Post.where(id: post_ids).in_batches.delete_all
  end

  # The self-referencing parent_scene_id link is broken before the scenes are
  # deleted so the delete is FK-safe.
  sig { void }
  def delete_scenes_and_children
    delete_scene_children
    scenes = Scene.where(id: scene_ids)
    scenes.update_all(parent_scene_id: nil)
    scenes.in_batches.delete_all
  end

  sig { void }
  def delete_scene_children
    SceneParticipant.where(scene_id: scene_ids).in_batches.delete_all
    delete_scene_summaries_and_versions
    NotificationPreference.where(scene_id: scene_ids).in_batches.delete_all
  end

  # A summary's versions reference it, so they go first — same child-before-parent
  # order as pages/notebook entries and their versions.
  sig { void }
  def delete_scene_summaries_and_versions
    ids = SceneSummary.where(scene_id: scene_ids).pluck(:id)
    SceneSummaryVersion.where(scene_summary_id: ids).in_batches.delete_all
    SceneSummary.where(id: ids).in_batches.delete_all
  end

  sig { void }
  def delete_characters_and_versions
    character_ids = @scope.character_ids
    CharacterVersion.where(character_id: character_ids).in_batches.delete_all
    CharacterImage.where(character_id: character_ids).in_batches.delete_all
    Character.where(id: character_ids).in_batches.delete_all
  end

  sig { void }
  def delete_game_owned_records
    delete_game_content_records
    delete_game_membership_records
  end

  # NotebookEntry may reference a Page via promoted_page_id, so it is deleted
  # before Page. A versioned child (NotebookEntryVersion, PageVersion) has a
  # not-null FK to its parent, so those rows are deleted before the parents.
  sig { void }
  def delete_game_content_records
    GameFile.where(game_id: game_id).in_batches.delete_all
    delete_notebook_entries_and_versions
    delete_pages_and_versions
    GameLink.where(game_id: game_id).in_batches.delete_all
    ContentTemplate.where(game_id: game_id).in_batches.delete_all
  end

  sig { void }
  def delete_notebook_entries_and_versions
    ids = NotebookEntry.where(game_id: game_id).pluck(:id)
    NotebookEntryVersion.where(notebook_entry_id: ids).in_batches.delete_all
    NotebookEntry.where(id: ids).in_batches.delete_all
  end

  # The game may reference one of its own pages as its environment page; that
  # FK is cleared before the pages are deleted so the delete is FK-safe (the
  # games row itself is deleted last, in #delete_all!).
  sig { void }
  def delete_pages_and_versions
    # unscoped: the game being purged is soft-deleted, so the default scope
    # would hide it and the nullify would no-op, leaving the FK to fail.
    Game.unscoped.where(id: game_id).update_all(environment_page_id: nil)
    ids = Page.where(game_id: game_id).pluck(:id)
    PageVersion.where(page_id: ids).in_batches.delete_all
    Page.where(id: ids).in_batches.delete_all
  end

  sig { void }
  def delete_game_membership_records
    Invitation.where(game_id: game_id).in_batches.delete_all
    GameMember.where(game_id: game_id).in_batches.delete_all
    GameExportRequest.where(game_id: game_id).in_batches.delete_all
    ApiToken.where(game_id: game_id).in_batches.delete_all
  end
end
