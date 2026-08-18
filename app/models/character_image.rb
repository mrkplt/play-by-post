# typed: true

# One image in a character's portrait library. The player uploads a
# square-cropped image, which lands here and (on upload) becomes the character's
# current portrait; the player may later mark any other library image current.
# Shared library behaviour — the attachment, validations, variants, and the
# make_current! exclusivity — lives in UploadedImage::Model.
class CharacterImage < ApplicationRecord
  extend T::Sig
  include UploadedImage::Model

  belongs_to :character

  has_one_attached :file
  validate :acceptable_image

  scope :current, -> { where(current: true) }

  sig { override.returns(Character) }
  def owner
    T.must(character)
  end

  # This character's other library images — every sibling but this one.
  sig { override.returns(T.untyped) }
  def siblings
    T.must(character).character_images.where.not(id: id)
  end
end
