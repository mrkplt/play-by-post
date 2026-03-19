class Post < ApplicationRecord
  EDIT_WINDOW = 10.minutes

  belongs_to :scene
  belongs_to :user

  has_one_attached :image

  IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  IMAGE_MAX_SIZE = 5.megabytes

  validates :content, presence: true

  def editable_by?(user)
    self.user == user && created_at > EDIT_WINDOW.ago
  end

  def within_edit_window?
    created_at > EDIT_WINDOW.ago
  end
end
