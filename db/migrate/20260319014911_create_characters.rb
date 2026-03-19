class CreateCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :characters do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :content
      t.boolean :active, null: false, default: true
      t.boolean :hidden, null: false, default: false

      t.timestamps
    end
  end
end
