# typed: false

# Server-side session storage for activerecord-session_store. Rows live in the
# primary database, which in production is the SQLite file on the mounted
# `/data` volume — so sessions persist across deploys and container restarts.
class AddSessionsTable < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps
    end

    add_index :sessions, :session_id, unique: true
    add_index :sessions, :updated_at
  end
end
