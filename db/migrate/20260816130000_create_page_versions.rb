# typed: false

# Pages gain change history the same way characters have it: a per-model
# versions table holding a full snapshot of the versioned fields (title and
# body) plus attribution, written on every save by Versionable::Model. Page is
# the classic wiki case for version history.
class CreatePageVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :page_versions do |t|
      t.references :page, null: false, foreign_key: true
      t.string :title
      t.text :body
      t.references :edited_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
