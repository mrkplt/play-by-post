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
    attached = file
    return "#" unless attached.attached?

    T.cast(@options.fetch(:helpers).rails_blob_path(attached, disposition: "attachment"), String)
  end

  sig { returns(T.nilable(String)) }
  def delete_url
    return nil unless @options[:can_manage]

    T.cast(@options.fetch(:helpers).game_game_file_path(@options.fetch(:game), @model), String)
  end

  sig { returns(T.nilable(String)) }
  def thumb_html
    thumb = thumbnail
    return nil unless thumb

    helpers = @options.fetch(:helpers)
    helpers.image_tag(helpers.url_for(thumb), alt: filename, loading: "lazy").to_s
  end

  sig { returns(String) }
  def lightbox_html
    helpers = @options.fetch(:helpers)
    tag = helpers.tag

    if image? && (display = display_image)
      tag.img(src: helpers.url_for(display), alt: filename).to_s
    elsif (thumb = thumbnail)
      tag.img(src: helpers.url_for(thumb), alt: filename, class: "max-w-full").to_s
    else
      tag.div(class: "flex flex-col items-center justify-center gap-3 p-8 text-slate-500", data: { testid: "lightbox-placeholder" }) do
        tag.div(file_extension, class: "text-5xl font-bold text-slate-400", data: { testid: "lightbox-placeholder-ext" }) +
        tag.div(human_file_size, class: "text-sm text-slate-400")
      end.to_s
    end
  end

  sig { returns(T::Boolean) }
  def error?
    @model.errors.any?
  end

  sig { returns(T.nilable(String)) }
  def error_message
    errors = @model.errors
    errors[:file].first || errors.full_messages.first
  end

  sig { returns(String) }
  def human_file_size
    attached = file
    return "" unless attached.attached?

    T.must(number_to_human_size(attached.byte_size))
  end

  sig { returns(T::Boolean) }
  def image?
    @model.image? # mutant:disable
  end

  sig { returns(T.nilable(T.any(ActiveStorage::VariantWithRecord, ActiveStorage::Preview))) }
  def thumbnail
    attached = file
    return unless attached.attached?

    if @model.image?
      attached.variant(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
    elsif @model.pdf? && attached.previewable?
      attached.preview(resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80)
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
    File.extname(@model.filename.to_s).delete(".").upcase.presence || content_type_extension
  end

  private

  sig { returns(String) }
  def content_type_extension
    attached = file
    return "" unless attached.attached?

    CONTENT_TYPE_EXTENSIONS.fetch(attached.content_type, "FILE")
  end
end
