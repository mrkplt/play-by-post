class CreateGameKeyAuthorizations < ActiveRecord::Migration[8.1]
  def change
    create_table :game_key_authorizations do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string     :feature, null: false
      t.timestamps
    end

    # One authorization per person, per game, per feature: a person may say
    # "my key funds summaries for this game" and "my key funds portraits for
    # this game" independently — two rows — but not the same one twice.
    add_index :game_key_authorizations, %i[game_id user_id feature], unique: true, name: "index_game_key_auth_on_game_user_feature"
    add_index :game_key_authorizations, %i[game_id feature]
  end
end
