# typed: strict

class Shared::TreeNodeComponent < ApplicationComponent
  extend T::Sig

  sig { params(node: T::Hash[Symbol, T.untyped], game: Game, depth: Integer).void }
  def initialize(node:, game:, depth: 0)
    @scene    = T.let(ScenePresenter.new(node[:scene]), ScenePresenter)
    @children = T.let(node[:children], T.untyped)
    @game     = T.let(game, Game)
    @depth    = T.let(depth, Integer)
  end
end
