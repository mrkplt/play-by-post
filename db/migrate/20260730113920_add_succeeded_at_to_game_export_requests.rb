class AddSucceededAtToGameExportRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :game_export_requests, :succeeded_at, :datetime

    # The receipt lookup asks "is there a successful export for this game in the
    # last 24h?" and takes the most recent — index by (game_id, succeeded_at desc)
    # so it is a fast indexed read, not a scan.
    add_index :game_export_requests, [ :game_id, :succeeded_at ],
      order: { succeeded_at: :desc },
      name: "index_game_export_requests_on_game_id_and_succeeded_at"
  end
end
