class CreateSceneSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :scene_summaries do |t|
      t.integer :scene_id, null: false
      t.text :body, null: false
      t.string :model_used
      t.datetime :generated_at
      t.integer :input_tokens
      t.integer :output_tokens
      t.datetime :edited_at
      t.integer :edited_by_id

      t.timestamps
    end

    add_index :scene_summaries, :scene_id, unique: true
    add_index :scene_summaries, :edited_by_id

    add_foreign_key :scene_summaries, :scenes
    add_foreign_key :scene_summaries, :users, column: :edited_by_id
  end
end
