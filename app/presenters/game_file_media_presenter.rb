# typed: strict

# The display metadata a game file's attachment carries on its own — size,
# extension, image/thumbnail derivation — with no dependency on a route or
# view helper. Split out of GameFilePresenter to keep that class under the
# project's method ceiling: these values need only the GameFile model, while
# GameFilePresenter's other methods need `game:`/`helpers:` to build links
# and inline markup.
class GameFileMediaPresenter < BasePresenter
  extend T::Sig
  include ActionView::Helpers::NumberHelper

  CONTENT_TYPE_EXTENSIONS = T.let({
    "application/pdf" => "PDF",
    "application/msword" => "DOC",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "DOCX",
    "text/plain" => "TXT",
    "text/markdown" => "MD"
  }.freeze, T::Hash[String, String])

  sig { params(model: GameFile, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def human_file_size
    sized = attached_file
    return "" unless sized

    T.must(number_to_human_size(sized.byte_size))
  end

  sig { returns(T::Boolean) }
  def image?
    @model.image? # mutant:disable
  end

  sig { returns(T.nilable(T.any(ActiveStorage::VariantWithRecord, ActiveStorage::Preview))) }
  def thumbnail
    previewable = attached_file
    return unless previewable

    if @model.image?
      previewable.variant(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    elsif @model.pdf? && previewable.previewable?
      previewable.preview(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    end
  end

  sig { returns(T.nilable(ActiveStorage::VariantWithRecord)) }
  def display_image
    @model.display_image # mutant:disable
  end

  sig { returns(T.untyped) }
  def file
    @model.file # mutant:disable
  end

  sig { returns(String) }
  def file_extension
    extension = File.extname(@model.filename.to_s).delete(".").upcase.presence
    return extension if extension

    typed = attached_file
    typed ? CONTENT_TYPE_EXTENSIONS.fetch(typed.content_type, "FILE") : ""
  end

  private

  # The underlying attachment, or nil when nothing is attached — the single
  # place that reads `file.attached?` so human_file_size/thumbnail/
  # file_extension don't each repeat the check.
  sig { returns(T.untyped) }
  def attached_file
    attached = file
    attached if attached.attached?
  end
end
