class Post < ApplicationRecord
  EDIT_WINDOW = 10.minutes

  belongs_to :scene
  belongs_to :user

  has_one_attached :image

  IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  IMAGE_MAX_SIZE = 10.megabytes

  validates :content, presence: true
  validate :acceptable_image

  def display_image
    image.variant(resize_to_limit: [ 800, nil ], format: :jpeg, quality: 85)
  end

  def editable_by?(user)
    self.user == user && created_at > EDIT_WINDOW.ago
  end

  def within_edit_window?
    created_at > EDIT_WINDOW.ago
  end

  private

  def acceptable_image
    return unless image.attached?

    unless image.blob.byte_size <= IMAGE_MAX_SIZE
      errors.add(:image, "must be less than 10MB")
    end

    unless IMAGE_TYPES.include?(image.blob.content_type)
      errors.add(:image, "must be a JPEG, PNG, GIF, or WebP image")
    end
  end
end
