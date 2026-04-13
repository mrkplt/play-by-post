# typed: strict

class GameFilePresenter < BasePresenter
  extend T::Sig
  include ActionView::Helpers::NumberHelper

  sig { returns(String) }
  def human_file_size
    return "" unless @model.file.attached?

    T.must(number_to_human_size(@model.file.byte_size))
  end

  sig { returns(T::Boolean) }
  def image?
    @model.image?
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
end
