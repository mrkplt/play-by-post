class AddProvenanceToSceneSummaries < ActiveRecord::Migration[8.1]
  def change
    add_column :scene_summaries, :generated_by_id, :integer
    add_column :scene_summaries, :cost, :decimal, precision: 10, scale: 6

    add_index :scene_summaries, :generated_by_id
    add_foreign_key :scene_summaries, :users, column: :generated_by_id
  end
end
