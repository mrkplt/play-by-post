# typed: false

# Character portraits can be AI-generated asynchronously, so a CharacterImage
# can exist as a "skeleton" before its file arrives:
#
#   - generated_at   : AI provenance (AiGenerated::Model) — stamped when the
#                      generated image is attached. Nil for an upload.
#   - failed_at      : set when a generation is blocked/failed; the row becomes
#                      a short-lived carrier for the player-facing failure, then
#                      is cleaned up once shown.
#   - failure_reason : the player-facing message for a failed generation.
#
# A skeleton (no file, not failed) is a pending generation; the frame-poll on
# the character screen watches for it to become ready (file attached) or failed.
class AddGenerationStateToCharacterImages < ActiveRecord::Migration[8.1]
  def change
    add_column :character_images, :generated_at, :datetime
    add_column :character_images, :failed_at, :datetime
    add_column :character_images, :failure_reason, :string
  end
end
