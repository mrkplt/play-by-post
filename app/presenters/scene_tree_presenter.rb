# typed: strict

# View model for the All Scenes screen's parent/child tree
# (ScenesController#index). Wraps the array of root nodes so the view asks
# "any scenes at all" of the presenter rather than the raw array. Each node
# is `{ scene:, children: }`, recursively — Shared::TreeNodeComponent already
# wraps `node[:scene]` in a ScenePresenter itself and walks `node[:children]`,
# so the node shape is left as-is for it to consume.
class SceneTreePresenter < BasePresenter
  extend T::Sig

  sig { params(model: T::Array[T::Hash[Symbol, T.untyped]], options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def empty?
    @model.empty?
  end

  sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def trees
    @model
  end
end
