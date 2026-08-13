class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.integer :user_id, null: false
      t.integer :game_id, null: false
      t.string :scope, null: false, default: "rss"
      t.string :token, null: false

      t.timestamps
    end

    add_index :api_tokens, %i[user_id scope game_id], unique: true
    add_index :api_tokens, :token, unique: true

    add_foreign_key :api_tokens, :users
    add_foreign_key :api_tokens, :games
  end
end
