# typed: strict

# One row of the scene tree (scenes/index) plus its children, recursively.
# A T::Struct rather than a type alias: the shape is self-referential
# (children are themselves Nodes), which a `T.type_alias` block cannot
# express — Sorbet evaluates its block eagerly, so a hash/array shape that
# refers to itself recurses forever. A named class reference does not have
# that problem. ScenePresenter, not Scene, is what the tree carries: this is
# how the scene tree stays clear of raw models end to end.
class Shared::TreeNodeComponent < ApplicationComponent
  extend T::Sig

  class Node < T::Struct
    const :scene_presenter, ScenePresenter
    const :children, T::Array[Node]
  end

  sig { params(node: Node, game_presenter: GamePresenter, depth: Integer).void }
  def initialize(node:, game_presenter:, depth: 0)
    @scene          = T.let(node.scene_presenter, ScenePresenter)
    @children       = T.let(node.children, T::Array[Node])
    @game_presenter = T.let(game_presenter, GamePresenter)
    @depth          = T.let(depth, Integer)
  end
end
