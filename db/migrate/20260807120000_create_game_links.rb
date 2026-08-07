class CreateGameLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :game_links do |t|
      t.references :game, null: false, foreign_key: true
      # A short human label for the link — shown as the row title on the Links
      # tab. The URL itself is never used as display text.
      t.string :description, null: false
      # The external URL the link points at. Validated on the model to be an
      # absolute http(s) URL, so links always leave the site via a real web
      # address (never a javascript: or other scheme).
      t.string :url, null: false

      t.timestamps
    end
  end
end
