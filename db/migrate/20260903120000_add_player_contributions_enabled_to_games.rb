# typed: false

# The GM-controlled setting (Fizzy #18) that lets active players create pages,
# links, and files in a game. Defaults off — existing games keep GM-only
# contribution until a GM opts in, matching the other game flags
# (sheets_hidden, ai_summaries_enabled).
class AddPlayerContributionsEnabledToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :player_contributions_enabled, :boolean, default: false, null: false
  end
end
