# typed: strict

# View model for a game file: display metadata (size, extension, thumbnail)
# plus, when constructed with `game:`/`helpers:` (the gallery needs both a
# route and view-helper access to build download/delete links and inline
# markup), the gallery's per-card download/delete URLs and lightbox/thumbnail
# HTML. Those two options are supplied at construction so the presenter never
# reaches for a route or view helper of its own; a caller that only needs the
# display metadata (file_extension, human_file_size, ...) can omit them.
class GameFilePresenter < BasePresenter
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
  def download_url
    downloadable = attached_file
    return "#" unless downloadable

    T.cast(@options.fetch(:helpers).rails_blob_path(downloadable, disposition: "attachment"), String)
  end

  sig { returns(T.nilable(String)) }
  def delete_url
    return nil unless @options[:can_manage]

    T.cast(@options.fetch(:helpers).game_game_file_path(@options.fetch(:game), @model), String)
  end

  # The gallery card's lazy-loaded thumbnail.
  sig { returns(T.nilable(String)) }
  def thumb_html
    thumb = thumbnail
    return nil unless thumb

    attachment_image_html(thumb, css_class: nil, loading: "lazy")
  end

  # The lightbox's best available visual: the full display image when this is
  # an image file, else the thumbnail (e.g. a PDF preview), else a
  # filename/size placeholder card.
  sig { returns(String) }
  def lightbox_html
    if image? && (display = display_image)
      attachment_image_html(display, css_class: nil, loading: nil)
    elsif (thumb = thumbnail)
      attachment_image_html(thumb, css_class: "max-w-full", loading: nil)
    else
      tag = @options.fetch(:helpers).tag
      tag.div(class: "flex flex-col items-center justify-center gap-3 p-8 text-slate-500", data: { testid: "lightbox-placeholder" }) do
        tag.div(file_extension, class: "text-5xl font-bold text-slate-400", data: { testid: "lightbox-placeholder-ext" }) +
        tag.div(human_file_size, class: "text-sm text-slate-400")
      end.to_s
    end
  end

  sig { returns(T::Boolean) }
  def error?
    error_message.present?
  end

  sig { returns(T.nilable(String)) }
  def error_message
    @model.error_message # mutant:disable
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

  sig { returns(String) }
  def filename
    @model.filename # mutant:disable
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

  # Shared by lightbox_html's image/thumbnail branches and thumb_html's
  # gallery-card thumbnail — one attachment rendered as an <img>, differing
  # only in the CSS class and lazy-load hint applied.
  sig do
    params(
      attachment: T.untyped,
      css_class: T.nilable(String),
      loading: T.nilable(String)
    ).returns(String)
  end
  def attachment_image_html(attachment, css_class:, loading:)
    helpers = @options.fetch(:helpers)
    helpers.tag.img(src: helpers.url_for(attachment), alt: filename, class: css_class, loading: loading).to_s
  end

  # The underlying attachment, or nil when nothing is attached — the single
  # place that reads `file.attached?` so download_url/human_file_size/
  # thumbnail/file_extension don't each repeat the check.
  sig { returns(T.untyped) }
  def attached_file
    attached = file
    attached if attached.attached?
  end
end
