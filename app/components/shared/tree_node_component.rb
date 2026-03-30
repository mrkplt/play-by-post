# typed: true

class Shared::TreeNodeComponent < ApplicationComponent
  extend T::Sig

  sig { params(node: T::Hash[Symbol, T.untyped], game: Game, depth: Integer).void }
  def initialize(node:, game:, depth: 0)
    @scene    = ScenePresenter.new(node[:scene])
    @children = node[:children]
    @game     = game
    @depth    = depth
  end
end
