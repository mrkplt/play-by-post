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

  sig { params(model: GameFile, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def download_url
    return "#" unless @model.file.attached?

    T.cast(@options.fetch(:helpers).rails_blob_path(@model.file, disposition: "attachment"), String)
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

    if image? && (display = display_image)
      helpers.tag.img(src: helpers.url_for(display), alt: filename).to_s
    elsif (thumb = thumbnail)
      helpers.tag.img(src: helpers.url_for(thumb), alt: filename, class: "max-w-full").to_s
    else
      helpers.tag.div(class: "flex flex-col items-center justify-center gap-3 p-8 text-slate-500", data: { testid: "lightbox-placeholder" }) do
        helpers.tag.div(file_extension, class: "text-5xl font-bold text-slate-400", data: { testid: "lightbox-placeholder-ext" }) +
        helpers.tag.div(human_file_size, class: "text-sm text-slate-400")
      end.to_s
    end
  end

  sig { returns(T::Boolean) }
  def error?
    @model.errors.any?
  end

  sig { returns(T.nilable(String)) }
  def error_message
    @model.errors[:file].first || @model.errors.full_messages.first
  end

  sig { returns(String) }
  def human_file_size
    return "" unless @model.file.attached?

    T.must(number_to_human_size(@model.file.byte_size))
  end

  sig { returns(T::Boolean) }
  def image?
    @model.image? # mutant:disable
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
