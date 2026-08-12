class ReworkRssTokensForScoping < ActiveRecord::Migration[8.1]
  def up
    # Existing tokens are dropped by design — scope changes from one-per-user to
    # per-user-per-game (plus a nullable account-level token), so old rows have no
    # valid game_id and old feed URLs are replaced by /feeds?token=.
    execute "DELETE FROM rss_tokens"

    add_reference :rss_tokens, :game, null: true, foreign_key: true

    remove_index :rss_tokens, :user_id
    add_index :rss_tokens, %i[user_id game_id], unique: true

    # SQLite treats NULLs as distinct in a unique index, so the composite index
    # above does NOT stop two account-level (game_id IS NULL) rows for one user.
    # This partial index is the DB backstop; the model validation is authoritative.
    add_index :rss_tokens, :user_id, unique: true, where: "game_id IS NULL",
                                     name: "index_rss_tokens_account_level"
  end

  def down
    execute "DELETE FROM rss_tokens"

    remove_index :rss_tokens, name: "index_rss_tokens_account_level"
    remove_index :rss_tokens, %i[user_id game_id]
    remove_reference :rss_tokens, :game, foreign_key: true

    add_index :rss_tokens, :user_id, unique: true
  end
end
