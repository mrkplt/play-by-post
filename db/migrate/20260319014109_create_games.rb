class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :sheets_hidden, null: false, default: false

      t.timestamps
    end
  end
end
