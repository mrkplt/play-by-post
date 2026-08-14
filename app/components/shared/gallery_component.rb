# typed: strict

# The Files tab's thumbnail grid plus its lightbox modal. Each file's
# download/delete URLs and thumbnail/lightbox markup are already resolved on
# its GameFilePresenter (built with game/helpers/can_manage at construction),
# so the component only lays out what it is handed.
class Shared::GalleryComponent < ApplicationComponent
  extend T::Sig

  sig { params(game_files: T::Array[GameFilePresenter], can_manage: T::Boolean).void }
  def initialize(game_files:, can_manage: false)
    @game_files = T.let(game_files, T::Array[GameFilePresenter])
    @can_manage = T.let(can_manage, T::Boolean)
  end

  sig { returns(T::Array[GameFilePresenter]) }
  attr_reader :game_files

  sig { returns(T::Boolean) }
  def can_manage?
    @can_manage
  end
end
