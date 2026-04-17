# typed: strict

class Shared::GalleryComponent < ApplicationComponent
  extend T::Sig

  sig { params(game_files: T::Array[GameFile], game: Game, is_gm: T::Boolean).void }
  def initialize(game_files:, game:, is_gm: false)
    @game_files = T.let(game_files.map { |gf| GameFilePresenter.new(gf) }, T::Array[GameFilePresenter])
    @game       = T.let(game, Game)
    @is_gm      = T.let(is_gm, T::Boolean)
  end

  private

  sig { params(gf: GameFilePresenter).returns(T.untyped) }
  def download_url_for(gf)
    gf.file.attached? ? T.unsafe(helpers).rails_blob_path(gf.file, disposition: "attachment") : "#"
  end

  sig { params(gf: GameFilePresenter).returns(T.untyped) }
  def delete_url_for(gf)
    return nil unless @is_gm
    T.unsafe(helpers).game_game_file_path(@game, gf)
  end

  sig { params(gf: GameFilePresenter).returns(T.untyped) }
  def thumb_html_for(gf)
    thumb = gf.thumbnail
    return nil unless thumb
    T.unsafe(helpers).image_tag(T.unsafe(helpers).url_for(thumb), alt: gf.filename, loading: "lazy")
  end

  sig { params(gf: GameFilePresenter).returns(T.untyped) }
  def lightbox_html_for(gf)
    if gf.image? && (display = gf.display_image)
      T.unsafe(helpers).tag.img(src: T.unsafe(helpers).url_for(display), alt: gf.filename).to_s
    elsif (thumb = gf.thumbnail)
      T.unsafe(helpers).tag.img(src: T.unsafe(helpers).url_for(thumb), alt: gf.filename, class: "max-w-full").to_s
    else
      T.unsafe(helpers).tag.div(class: "flex flex-col items-center justify-center gap-3 p-8 text-slate-500", data: { testid: "lightbox-placeholder" }) do
        T.unsafe(helpers).tag.div(gf.file_extension, class: "text-5xl font-bold text-slate-400", data: { testid: "lightbox-placeholder-ext" }) +
        T.unsafe(helpers).tag.div(gf.human_file_size, class: "text-sm text-slate-400")
      end.to_s
    end
  end
end
