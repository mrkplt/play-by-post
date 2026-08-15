# typed: strict
# frozen_string_literal: true

# A scene whose parent is missing from the list (private, or outside the
# viewer's scope) roots its own branch, so nothing is orphaned.
class SceneTreeBuilder
  extend T::Sig

  sig { params(scenes: T::Array[Scene]).void }
  def initialize(scenes)
    @scenes = scenes
  end

  sig { params(user: User, game: Game).returns(SceneTreeBuilder) }
  def self.for(user, game)
    scenes = ScenePolicy::Scope.new(user, game).resolve
      .includes(:parent_scene, :child_scenes, scene_participants: [ :character, :user ])
      .order(created_at: :asc)
      .to_a

    new(scenes)
  end

  sig { returns(SceneTreePresenter) }
  def call
    SceneTreePresenter.new(roots.map { |root| node_for(root) })
  end

  private

  sig { returns(T::Array[Scene]) }
  def roots
    @scenes.select { |scene| root?(scene.parent_scene_id) }
  end

  sig { params(parent_id: T.nilable(Integer)).returns(T::Boolean) }
  def root?(parent_id)
    parent_id.nil? || by_id[parent_id].nil?
  end

  sig { returns(T::Hash[Integer, Scene]) }
  def by_id
    @by_id ||= T.let(@scenes.index_by(&:id), T.nilable(T::Hash[Integer, Scene]))
  end

  sig { returns(T::Hash[T.nilable(Integer), T::Array[Scene]]) }
  def children_by_parent_id
    @children_by_parent_id ||= T.let(
      @scenes.sort_by(&:created_at).group_by(&:parent_scene_id),
      T.nilable(T::Hash[T.nilable(Integer), T::Array[Scene]])
    )
  end

  sig { params(scene: Scene).returns(Shared::TreeNodeComponent::Node) }
  def node_for(scene)
    children = children_by_parent_id.fetch(scene.id, [])

    Shared::TreeNodeComponent::Node.new(
      scene_presenter: ScenePresenter.new(scene),
      children: children.map { |child| node_for(child) }
    )
  end
end
