# typed: false

# The per-user half of the AI Control Plane's display model: independent of
# generation/consent (ai_summaries_consent, producing), this controls how a
# viewer's OWN client renders AI-generated assets they encounter (consuming).
# Three states — shown (subtle, no loud badge), tagged (prominent
# "AI-generated" badge), hidden (AI-generated rows filtered out of the
# viewer's index/scene view/RSS entirely). Defaults to "tagged": the safe
# default is to always disclose, matching the app's privacy/disclosure
# posture, without going as far as hiding content nobody asked to hide.
class AddAiDisplayPreferenceToUserProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :user_profiles, :ai_display_preference, :integer, default: 1, null: false
  end
end
