class CreateScenes < ActiveRecord::Migration[8.0]
  def change
    create_table :scenes do |t|
      t.references :game, null: false, foreign_key: true
      t.references :parent_scene, foreign_key: { to_table: :scenes }, null: true
      t.string :title, null: false
      t.text :description
      t.boolean :private, null: false, default: false
      t.datetime :resolved_at
      t.text :resolution

      t.timestamps
    end
  end
end
