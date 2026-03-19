class CreateGameMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :game_members do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :game_members, %i[game_id user_id], unique: true
  end
end
