# typed: true

# Bundles the id sets a game purge operates over, computed once from the game
# so every purge/delete step reads from here instead of re-deriving (or
# re-calling game.id) at each call site.
class GamePurgeScope
  extend T::Sig

  sig { returns(Game) }
  attr_reader :game

  sig { returns(T::Array[Integer]) }
  attr_reader :scene_ids

  sig { returns(T::Array[Integer]) }
  attr_reader :post_ids

  sig { returns(T::Array[Integer]) }
  attr_reader :character_ids

  sig do
    params(
      game: Game,
      scene_ids: T::Array[Integer],
      post_ids: T::Array[Integer],
      character_ids: T::Array[Integer]
    ).void
  end
  def initialize(game:, scene_ids:, post_ids:, character_ids:)
    @game = game
    @scene_ids = scene_ids
    @post_ids = post_ids
    @character_ids = character_ids
  end

  sig { params(game: Game).returns(GamePurgeScope) }
  def self.for(game)
    game_id = game.id
    scene_ids = Scene.where(game_id: game_id).pluck(:id)
    post_ids = Post.where(scene_id: scene_ids).pluck(:id)
    character_ids = Character.where(game_id: game_id).pluck(:id)

    new(game: game, scene_ids: scene_ids, post_ids: post_ids, character_ids: character_ids)
  end

  sig { returns(Integer) }
  def game_id
    game.id
  end

  # Delete every record belonging to the game, children before parents so no
  # foreign key is violated, in batches to bound memory. Attachments are
  # already purged by the caller, so these are plain deletes — no cascade,
  # no callbacks.
  sig { void }
  def delete_all_dependents!
    delete_posts_and_reads
    delete_scenes_and_children
    delete_characters_and_versions
    delete_game_owned_records
    game.delete
  end

  private

  sig { void }
  def delete_posts_and_reads
    PostRead.where(post_id: post_ids).in_batches.delete_all
    Post.where(id: post_ids).in_batches.delete_all
  end

  # Deletes every scene-scoped record: participants, summaries, notification
  # preferences, then the scenes themselves. The self-referencing
  # parent_scene_id link is broken first so the scene delete is FK-safe.
  sig { void }
  def delete_scenes_and_children
    delete_scene_children
    unlink_and_delete_scenes
  end

  sig { void }
  def delete_characters_and_versions
    CharacterVersion.where(character_id: character_ids).in_batches.delete_all
    Character.where(id: character_ids).in_batches.delete_all
  end

  sig { void }
  def delete_game_owned_records
    delete_game_content_records
    delete_game_membership_records
  end

  # NotebookEntry may reference a Page via promoted_page_id, so it is deleted
  # before Page. PageVersion has a not-null FK to Page, so its rows are deleted
  # before their pages (mirroring CharacterVersion → Character above).
  sig { void }
  def delete_game_content_records
    GameFile.where(game_id: game_id).in_batches.delete_all
    NotebookEntry.where(game_id: game_id).in_batches.delete_all
    delete_pages_and_versions
    GameLink.where(game_id: game_id).in_batches.delete_all
    ContentTemplate.where(game_id: game_id).in_batches.delete_all
  end

  # PageVersion has a not-null FK to Page, so its rows go before their pages
  # (mirroring CharacterVersion → Character). Page ids are plucked once into a
  # local so both deletes target the same set without a duplicate query.
  sig { void }
  def delete_pages_and_versions
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

  sig { void }
  def delete_scene_children
    SceneParticipant.where(scene_id: scene_ids).in_batches.delete_all
    SceneSummary.where(scene_id: scene_ids).in_batches.delete_all
    NotificationPreference.where(scene_id: scene_ids).in_batches.delete_all
  end

  sig { void }
  def unlink_and_delete_scenes
    unlink_scenes
    delete_scenes
  end

  sig { void }
  def unlink_scenes
    Scene.where(id: scene_ids).update_all(parent_scene_id: nil)
  end

  sig { void }
  def delete_scenes
    Scene.where(id: scene_ids).in_batches.delete_all
  end
end
