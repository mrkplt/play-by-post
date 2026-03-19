class CreateGameFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :game_files do |t|
      t.references :game, null: false, foreign_key: true
      t.string :filename
      t.string :content_type
      t.integer :byte_size

      t.timestamps
    end
  end
end
