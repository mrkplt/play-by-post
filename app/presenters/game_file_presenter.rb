# typed: strict

# View model for a game file: the gallery's download/delete URLs and
# lightbox/thumbnail HTML, built with `game:`/`helpers:` (the gallery needs
# both a route and view-helper access). Display metadata that needs only the
# GameFile model (size, extension, image derivation) lives on
# GameFileMediaPresenter, reached via #media — split out to keep this class
# under the project's method ceiling. A caller that only needs display
# metadata can build GameFileMediaPresenter directly.
class GameFilePresenter < BasePresenter
  extend T::Sig

  sig { params(model: GameFile, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def download_url
    downloadable = media.file
    return "#" unless downloadable.attached?

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
    thumb = media.thumbnail
    return nil unless thumb

    attachment_image_html(thumb, css_class: nil, loading: "lazy")
  end

  # The lightbox's best available visual: the full display image when this is
  # an image file, else the thumbnail (e.g. a PDF preview), else a
  # filename/size placeholder card.
  sig { returns(String) }
  def lightbox_html
    if media.image? && (display = media.display_image)
      attachment_image_html(display, css_class: nil, loading: nil)
    elsif (thumb = media.thumbnail)
      attachment_image_html(thumb, css_class: "max-w-full", loading: nil)
    else
      tag = @options.fetch(:helpers).tag
      tag.div(class: "flex flex-col items-center justify-center gap-3 p-8 text-meta-500", data: { testid: "lightbox-placeholder" }) do
        tag.div(file_extension, class: "text-5xl font-bold text-meta-400", data: { testid: "lightbox-placeholder-ext" }) +
        tag.div(media.human_file_size, class: "text-sm text-meta-400")
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
  def filename
    @model.filename # mutant:disable
  end

  sig { returns(String) }
  def file_extension
    media.file_extension
  end

  private

  sig { returns(GameFileMediaPresenter) }
  def media
    GameFileMediaPresenter.new(@model)
  end

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
end
