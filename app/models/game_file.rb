class GameFile < ApplicationRecord
  belongs_to :game

  has_one_attached :file

  ALLOWED_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    text/plain
    text/markdown
    image/jpeg
    image/png
    image/gif
    image/webp
  ].freeze

  MAX_SIZE = 25.megabytes

  validates :filename, presence: true
  validate :acceptable_file

  private

  def acceptable_file
    return unless file.attached?

    unless file.byte_size <= MAX_SIZE
      errors.add(:file, "must be less than 25MB")
    end

    unless ALLOWED_TYPES.include?(file.content_type)
      errors.add(:file, "must be a PDF, Word doc, text, markdown, or image file")
    end
  end
end
