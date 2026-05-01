class AddAiSummariesEnabledToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :ai_summaries_enabled, :boolean, default: false, null: false
  end
end
