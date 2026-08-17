# typed: false

# Notebook entries gain change history the same way pages and characters have
# it: a per-model versions table holding a full snapshot of the versioned fields
# (title and body) plus attribution, written on every save by
# Versionable::Model. Status and promotion do not snapshot — only the editable
# title/body do.
class CreateNotebookEntryVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :notebook_entry_versions do |t|
      t.references :notebook_entry, null: false, foreign_key: true
      t.string :title
      t.text :body
      t.references :edited_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
