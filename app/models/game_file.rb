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

  MAX_SIZE = T.let(50.megabytes, Integer)

  validates :filename, presence: true
  validate :acceptable_file

  sig { returns(T::Boolean) }
  def image?
    IMAGE_TYPES.include?(attached_content_type)
  end

  sig { returns(T::Boolean) }
  def pdf?
    attached_content_type == "application/pdf"
  end

  sig { returns(T::Boolean) }
  def thumbnailable?
    image? || pdf?
  end

  sig { returns(T.nilable(ActiveStorage::VariantWithRecord)) }
  def display_image
    return unless image?

    file.variant(resize_to_limit: [ 800, nil ], format: :jpeg, quality: 85)
  end

  # The most relevant validation message to surface in the upload form: the
  # unprefixed :file-specific message when there is one (an invalid/oversized
  # file), otherwise the first full message (e.g. a blank filename).
  sig { returns(T.nilable(String)) }
  def error_message
    errors[:file].first || errors.full_messages.first
  end

  private

  # The attached file's content type, or nil when nothing is attached — the
  # single place that guards on attachment presence so image?/pdf?/
  # acceptable_file don't each repeat the `attached?` check.
  sig { returns(T.nilable(String)) }
  def attached_content_type
    file.content_type if file.attached?
  end

  sig { void }
  def acceptable_file
    return unless (content_type = attached_content_type)

    unless T.must(file.byte_size) <= MAX_SIZE
      errors.add(:file, "must be less than #{MAX_SIZE / 1.megabyte}MB")
    end

    unless ALLOWED_TYPES.include?(content_type)
      errors.add(:file, "must be a PDF, Word doc, text, markdown, or image file")
    end
  end
end
