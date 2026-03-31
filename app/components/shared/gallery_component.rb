# typed: true

class Shared::GalleryComponent < ApplicationComponent
  extend T::Sig

  sig { params(game_files: T::Array[GameFile], game: Game, is_gm: T::Boolean).void }
  def initialize(game_files:, game:, is_gm: false)
    @game_files = game_files.map { |gf| GameFilePresenter.new(gf) }
    @game       = game
    @is_gm      = is_gm
  end
end
