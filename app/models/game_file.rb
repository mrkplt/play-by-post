# typed: true

class GameFile < ApplicationRecord
  extend T::Sig

  belongs_to :game

  has_one_attached :file

  ALLOWED_TYPES = T.let(%w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    text/plain
    text/markdown
    image/jpeg
    image/png
    image/gif
    image/webp
  ].freeze, T::Array[String])

  IMAGE_TYPES = T.let(%w[image/jpeg image/png image/gif image/webp].freeze, T::Array[String])

  MAX_SIZE = T.let(25.megabytes, Integer)

  validates :filename, presence: true
  validate :acceptable_file

  sig { returns(T::Boolean) }
  def image?
    return false unless file.attached?

    IMAGE_TYPES.include?(file.content_type)
  end

  sig { returns(T::Boolean) }
  def pdf?
    return false unless file.attached?

    file.content_type == "application/pdf"
  end

  sig { returns(T::Boolean) }
  def thumbnailable?
    image? || pdf?
  end

  sig { returns(T.nilable(T.any(ActiveStorage::VariantWithRecord, ActiveStorage::Preview))) }
  def thumbnail
    return unless file.attached?

    if image?
      file.variant(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    elsif pdf? && file.previewable?
      file.preview(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    end
  end

  sig { returns(T.nilable(ActiveStorage::VariantWithRecord)) }
  def display_image
    return unless file.attached? && image?

    file.variant(resize_to_limit: [ 800, nil ], format: :jpeg, quality: 85)
  end

  sig { returns(String) }
  def file_extension
    File.extname(filename.to_s).delete(".").upcase.presence || content_type_extension
  end

  private

  sig { returns(String) }
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

  sig { void }
  def acceptable_file
    return unless file.attached?

    unless T.must(file.byte_size) <= MAX_SIZE
      errors.add(:file, "must be less than 25MB")
    end

    unless ALLOWED_TYPES.include?(file.content_type)
      errors.add(:file, "must be a PDF, Word doc, text, markdown, or image file")
    end
  end
end
