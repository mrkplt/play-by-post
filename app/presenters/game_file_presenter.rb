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
    return unless @model.file.attached?

    if @model.image?
      @model.file.variant(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    elsif @model.pdf? && @model.file.previewable?
      @model.file.preview(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    end
  end

  sig { returns(String) }
  def filename
    @model.filename
  end

  sig { returns(T.nilable(ActiveStorage::VariantWithRecord)) }
  def display_image
    @model.display_image
  end

  sig { returns(T.untyped) }
  def file
    @model.file
  end

  sig { returns(String) }
  def file_extension
    File.extname(@model.filename.to_s).delete(".").upcase.presence || content_type_extension
  end

  private

  sig { returns(String) }
  def content_type_extension
    return "" unless @model.file.attached?

    case @model.file.content_type
    when "application/pdf" then "PDF"
    when "application/msword" then "DOC"
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document" then "DOCX"
    when "text/plain" then "TXT"
    when "text/markdown" then "MD"
    else "FILE"
    end
  end
end
