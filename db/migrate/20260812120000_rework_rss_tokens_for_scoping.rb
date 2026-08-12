class ReworkRssTokensForScoping < ActiveRecord::Migration[8.1]
  def up
    # Existing tokens are dropped by design — scope changes from one-per-user to
    # per-user-per-game, so old rows have no valid game_id and old feed URLs are
    # replaced by /feeds?token=.
    execute "DELETE FROM rss_tokens"

    add_reference :rss_tokens, :game, null: false, foreign_key: true

    remove_index :rss_tokens, :user_id
    add_index :rss_tokens, %i[user_id game_id], unique: true
  end

  def down
    execute "DELETE FROM rss_tokens"

    remove_index :rss_tokens, %i[user_id game_id]
    remove_reference :rss_tokens, :game, foreign_key: true

    add_index :rss_tokens, :user_id, unique: true
  end
end
