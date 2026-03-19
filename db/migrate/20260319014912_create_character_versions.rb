class CreateCharacterVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :character_versions do |t|
      t.references :character, null: false, foreign_key: true
      t.text :content
      t.references :edited_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
