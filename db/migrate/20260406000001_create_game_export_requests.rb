class CreateGameExportRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :game_export_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: true, foreign_key: true

      t.timestamps
    end

    add_index :game_export_requests, [ :user_id, :game_id ]
  end
end
