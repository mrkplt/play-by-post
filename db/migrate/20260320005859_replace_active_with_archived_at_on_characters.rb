class ReplaceActiveWithArchivedAtOnCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :archived_at, :datetime
    reversible do |dir|
      dir.up { execute "UPDATE characters SET archived_at = updated_at WHERE active = 0" }
    end
    remove_column :characters, :active, :boolean, null: false, default: true
  end
end
