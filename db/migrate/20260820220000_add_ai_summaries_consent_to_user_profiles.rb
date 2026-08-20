# typed: false

# The per-user half of the AI Control Plane's two-gate consent model: a game's
# AI summaries stay off for a user unless BOTH the GM has switched the game on
# (Game#ai_summaries_enabled, existing) AND the relevant user has opted in
# here. Defaults false (opt-in) — matches the app's privacy posture of not
# running AI over anyone's content without an affirmative choice, and mirrors
# how ai_key_reference (BYOK) is never assumed present.
class AddAiSummariesConsentToUserProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :user_profiles, :ai_summaries_consent, :boolean, default: false, null: false
  end
end
