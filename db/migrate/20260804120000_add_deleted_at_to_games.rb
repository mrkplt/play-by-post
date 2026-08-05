class AddDeletedAtToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :deleted_at, :datetime

    # Soft-deleted games are hidden by a default scope (deleted_at IS NULL) and the
    # daily purge sweep scans for deleted_at older than the retention window — both
    # are indexed reads, not scans.
    add_index :games, :deleted_at
  end
end
