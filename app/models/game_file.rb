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

  IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  MAX_SIZE = 25.megabytes

  validates :filename, presence: true
  validate :acceptable_file

  def image?
    file.attached? && IMAGE_TYPES.include?(file.content_type)
  end

  def pdf?
    file.attached? && file.content_type == "application/pdf"
  end

  def thumbnailable?
    image? || pdf?
  end

  def thumbnail
    return unless file.attached?

    if image?
      file.variant(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    elsif pdf? && file.previewable?
      file.preview(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    end
  end

  def display_image
    return unless file.attached? && image?

    file.variant(resize_to_limit: [ 800, nil ], format: :jpeg, quality: 85)
  end

  def file_extension
    File.extname(filename).delete(".").upcase.presence || content_type_extension
  end

  private

  def content_type_extension
    return "" unless file.attached?

    case file.content_type
    when "application/pdf" then "PDF"
    when "application/msword" then "DOC"
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document" then "DOCX"
    when "text/plain" then "TXT"
    when "text/markdown" then "MD"
    else "FILE"
    end
  end

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
