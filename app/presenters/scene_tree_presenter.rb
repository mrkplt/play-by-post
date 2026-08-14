# typed: strict

# View model for the All Scenes screen's parent/child tree
# (ScenesController#index). Wraps the array of root nodes so the view asks
# "any scenes at all" of the presenter rather than the raw array. Each node
# is a Shared::TreeNodeComponent::Node (scene_presenter + children,
# recursively) — the same shape the component itself declares — so the tree
# stays clear of raw models end to end.
class SceneTreePresenter < BasePresenter
  extend T::Sig

  sig { params(model: T::Array[Shared::TreeNodeComponent::Node], options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def empty?
    @model.empty?
  end

  sig { returns(T::Array[Shared::TreeNodeComponent::Node]) }
  def trees
    @model
  end
end
