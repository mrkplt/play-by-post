# typed: strict

class Shared::GalleryComponent < ApplicationComponent
  extend T::Sig

  sig { params(game_files: T::Array[GameFile], game: Game, is_gm: T::Boolean).void }
  def initialize(game_files:, game:, is_gm: false)
    @game_files = T.let(game_files.map { |gf| GameFilePresenter.new(gf) }, T::Array[GameFilePresenter])
    @game       = T.let(game, Game)
    @is_gm      = T.let(is_gm, T::Boolean)
  end
end
