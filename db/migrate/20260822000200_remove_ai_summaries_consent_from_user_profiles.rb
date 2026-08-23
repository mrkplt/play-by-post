# Drops the per-user AI-summaries production consent. The per-user AI control is
# now solely ai_display_preference (whose `hidden` state opts the viewer out of
# seeing AI content); scene-summary generation is gated only by the GM's
# game-level Game#ai_summaries_enabled. See SceneResolution.
class RemoveAiSummariesConsentFromUserProfiles < ActiveRecord::Migration[8.1]
  def change
    remove_column :user_profiles, :ai_summaries_consent, :boolean, default: false, null: false
  end
end
