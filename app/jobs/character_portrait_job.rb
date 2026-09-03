# typed: true

# Runs the AI portrait generation for a pending skeleton CharacterImage the
# controller already created. The work is a pipeline owned by
# CharacterPortraitGeneration (compose -> moderate -> generate -> complete the
# skeleton, or fail it); this job only resolves the skeleton and hands off, so
# the process is testable off the queue.
#
# The skeleton is passed by id (not the whole record) so no image bytes are ever
# serialized into the Solid Queue job payload.
class CharacterPortraitJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(character_image_id: Integer, requested_by_id: Integer, player_prompt: String).void }
  def perform(character_image_id, requested_by_id, player_prompt)
    image = CharacterImage.find_by(id: character_image_id)
    return if image.nil? || !image.pending?

    CharacterPortraitGeneration.new(image, requested_by_id, player_prompt).run
  end
end
