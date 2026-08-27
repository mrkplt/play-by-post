class CreateAiGenerations < ActiveRecord::Migration[8.1]
  def up
    create_table :ai_generations, id: :primary_key do |t|
      t.string   :feature,         null: false
      t.string   :model_used,      null: false
      t.integer  :input_tokens
      t.integer  :output_tokens
      t.decimal  :cost,            precision: 10, scale: 6
      t.integer  :requested_by_id, null: false
      t.integer  :funded_by_id,    null: false
      t.string   :asset_type,      null: false
      t.integer  :asset_id,        null: false
      t.datetime :created_at,      null: false
    end

    add_index :ai_generations, :requested_by_id
    add_index :ai_generations, :funded_by_id
    add_index :ai_generations, [ :asset_type, :asset_id ]
    add_index :ai_generations, :created_at

    # Backfill: every scene_summaries row that was actually AI-generated
    # (generated_at, generated_by_id, and model_used all present) becomes one
    # permanent audit row before the source columns are dropped below.
    # Historically the GM who generated the summary was also the one whose key
    # paid — requested_by_id and funded_by_id are both generated_by_id.
    execute <<~SQL.squish
      INSERT INTO ai_generations
        (feature, model_used, input_tokens, output_tokens, cost,
         requested_by_id, funded_by_id, asset_type, asset_id, created_at)
      SELECT
        'scene_summary', model_used, input_tokens, output_tokens, cost,
        generated_by_id, generated_by_id, 'SceneSummary', id, generated_at
      FROM scene_summaries
      WHERE generated_at IS NOT NULL
        AND generated_by_id IS NOT NULL
        AND model_used IS NOT NULL
    SQL

    remove_foreign_key :scene_summaries, :users, column: :generated_by_id
    remove_index :scene_summaries, :generated_by_id
    remove_column :scene_summaries, :cost
    remove_column :scene_summaries, :input_tokens
    remove_column :scene_summaries, :output_tokens
    remove_column :scene_summaries, :model_used
    remove_column :scene_summaries, :generated_by_id
  end

  # Audit rows are permanent — never deleted, by any path, including a
  # rollback. Reversing this migration would drop the ai_generations table
  # and every audit row in it, so it is deliberately irreversible.
  def down
    raise ActiveRecord::IrreversibleMigration, "ai_generations is a permanent audit trail; it is never dropped"
  end
end
