# typed: true

# One image in a user's avatar library. Identical in shape to CharacterImage —
# a square-cropped upload that becomes the user's current avatar and can be
# swapped for any other library image. Shared library behaviour lives in
# UploadedImage::Model; only the owner association differs.
class UserImage < ApplicationRecord
  extend T::Sig
  include UploadedImage::Model

  belongs_to :user

  has_one_attached :file
  validate :acceptable_image

  scope :current, -> { where(current: true) }

  sig { override.returns(User) }
  def owner
    T.must(user)
  end

  # This user's other library images — every sibling but this one.
  sig { override.returns(T.untyped) }
  def siblings
    T.must(user).user_images.where.not(id: id)
  end
end
