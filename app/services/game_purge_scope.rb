# typed: true

# The id sets a game purge operates over, computed once from the game so every
# delete step reads from here instead of re-deriving (or re-calling game.id) at
# each call site. A value object (T::Struct) the deletion order in
# GamePurgeDeletion reads from.
class GamePurgeScope < T::Struct
  extend T::Sig

  const :game, Game
  const :scene_ids, T::Array[Integer]
  const :post_ids, T::Array[Integer]
  const :character_ids, T::Array[Integer]

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

  # Delete every record belonging to the game, children before parents. The
  # order lives in GamePurgeDeletion; the caller wraps this in a transaction.
  sig { void }
  def delete_all_dependents!
    GamePurgeDeletion.new(self).delete_all!
  end
end
