# typed: true

# One image in a character's portrait library. Two creation paths:
#
#   - Upload: the player uploads a square-cropped image, which lands here with a
#     file attached and (on upload) becomes the character's current portrait.
#   - AI generation: a skeleton row is created first (no file), then the worker
#     either completes it (attaches the generated file, stamps generated_at) or
#     marks it failed. A skeleton is a pending generation the character screen's
#     frame-poll watches; only rows with a file attached are real portraits.
#
# Shared library behaviour — the attachment, variants, make_current! — lives in
# UploadedImage::Model; AI provenance (generated_at) in AiGenerated::Model.
class CharacterImage < ApplicationRecord
  extend T::Sig
  include UploadedImage::Model
  include AiGenerated::Model

  belongs_to :character

  has_one_attached :file

  # Only a row that actually has a file is validated as an image — a pending or
  # failed generation skeleton legitimately has none. (A conditional validation,
  # not a lifecycle callback, so bin/check-callbacks is satisfied.)
  validate :acceptable_image, if: :file_attached?

  # Real portraits: a file is attached. The library lists only these — skeletons
  # (pending) and failed rows never render as portraits.
  scope :ready, -> { joins(:file_attachment) }
  scope :current, -> { where(current: true) }
  # A character's pending generation skeleton: no file yet, not failed.
  scope :pending, -> { where(failed_at: nil).where.missing(:file_attachment) }
  scope :failed, -> { where.not(failed_at: nil) }

  sig { override.returns(Character) }
  def owner
    T.must(character)
  end

  # This character's other library images — every sibling but this one.
  sig { override.returns(T.untyped) }
  def siblings
    T.must(character).character_images.where.not(id: id)
  end

  sig { returns(T::Boolean) }
  def file_attached?
    file.attached?
  end

  # Whether this row is a pending AI-generation skeleton (no file, not failed).
  sig { returns(T::Boolean) }
  def pending?
    !file_attached? && failed_at.nil?
  end

  sig { returns(T::Boolean) }
  def failed?
    failed_at.present?
  end

  # Complete a generation: attach the generated file and stamp AI provenance,
  # making the skeleton a real, AI-authored portrait.
  sig { params(attachable: T.untyped).void }
  def complete_generation!(attachable)
    file.attach(attachable)
    update!(generated_at: Time.current)
  end

  # Mark a generation failed, turning the skeleton into a short-lived carrier
  # for the player-facing reason (cleaned up once shown).
  sig { params(reason: String).void }
  def fail_generation!(reason)
    update!(failed_at: Time.current, failure_reason: reason)
  end

  # Read the failure reason and destroy this dead skeleton — the reason is shown
  # to the player exactly once, then the row is gone (no dead rows linger).
  sig { returns(T.nilable(String)) }
  def consume_failure_reason!
    reason = failure_reason
    destroy
    reason
  end
end
