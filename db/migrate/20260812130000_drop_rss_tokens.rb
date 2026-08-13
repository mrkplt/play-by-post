class DropRssTokens < ActiveRecord::Migration[8.1]
  def up
    drop_table :rss_tokens
  end

  def down
    create_table :rss_tokens do |t|
      t.integer :user_id, null: false
      t.string :token, null: false

      t.timestamps
    end

    add_index :rss_tokens, :user_id, unique: true
    add_index :rss_tokens, :token, unique: true

    add_foreign_key :rss_tokens, :users
  end
end
