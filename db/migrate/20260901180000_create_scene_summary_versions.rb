# typed: false

# Scene summaries gain change history like pages and characters: a per-model
# versions table holding a full snapshot of the versioned fields plus
# attribution, written on every save by Versionable::Model. Unlike the other
# adopters, a summary version also snapshots `generated_at` — whether *that*
# revision was AI-authored — so the AI-generated fact is a provable per-revision
# historical record, not just a live flag.
class CreateSceneSummaryVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :scene_summary_versions do |t|
      t.references :scene_summary, null: false, foreign_key: true
      t.text :body
      t.datetime :generated_at
      t.references :edited_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
