# typed: true

# A point-in-time snapshot of a scene summary's body and AI-provenance, written
# by Versionable::Model on every save, with the editor (or, for an AI
# generation, the requester) who produced the change. `generated_at` records
# whether this particular revision was AI-authored.
class SceneSummaryVersion < ApplicationRecord
  extend T::Sig

  belongs_to :scene_summary
  belongs_to :edited_by, class_name: "User"
end
