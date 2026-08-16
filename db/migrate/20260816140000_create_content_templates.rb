# typed: false

# Per-game markdown templates that seed new content of a given type. One
# template per (game, content_type) — a unique index enforces it — where
# content_type is page, note, or character. Deliberately separate storage rather
# than a boolean on the content rows: a template is configuration, not content,
# so it never appears in a listing, is never versioned, and is never draftable.
class CreateContentTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :content_templates do |t|
      t.references :game, null: false, foreign_key: true
      t.string :content_type, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :content_templates, [ :game_id, :content_type ], unique: true
  end
end
