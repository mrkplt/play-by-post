class CreateAiUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_usages do |t|
      t.string  :feature,      null: false
      t.string  :model_used,   null: false
      t.integer :input_tokens
      t.integer :output_tokens
      t.datetime :created_at,  null: false
    end

    add_index :ai_usages, :feature
    add_index :ai_usages, :created_at
  end
end
