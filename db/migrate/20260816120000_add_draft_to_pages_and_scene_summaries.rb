# typed: false

# Drafting is extracted into a shared Draftable concern (was Post-only). Pages
# and scene summaries gain the same `draft` boolean Post already has: a record
# is a draft until published, and a draft is hidden from non-authors. Every
# existing row is already-published content, so the `false` default backfills
# them correctly with no data migration.
#
# Per the owner decision, draft is a plain boolean on the row — editing a
# published record never pulls the published text away, so no shadow copy or
# separate draft row is needed.
class AddDraftToPagesAndSceneSummaries < ActiveRecord::Migration[8.1]
  def change
    add_column :pages, :draft, :boolean, default: false, null: false
    add_column :scene_summaries, :draft, :boolean, default: false, null: false
  end
end
