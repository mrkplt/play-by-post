# typed: strict

# View model for one row of the scenes/index tree (Shared::TreeNodeComponent).
# Wraps a ScenePresenter — composition, not duplication — so the tree-only
# display concerns (row/link CSS class, the tree's status-badge pairing,
# the created-at stamp) live apart from ScenePresenter's broader surface
# (scene card, composer, resolve form, ...) without re-deriving anything
# ScenePresenter already knows how to say.
class SceneTreeRowPresenter < BasePresenter
  extend T::Sig

  sig { params(model: ScenePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The wrapped ScenePresenter, for the tree row's link — the route helper
  # needs a Scene-mappable object, and this is the presenter that already
  # knows how to answer that (its own #model returns the raw Scene).
  sig { returns(ScenePresenter) }
  def scene_presenter
    @model
  end

  sig { returns(String) }
  def title
    @model.title
  end

  sig { returns(String) }
  def tree_row_css_class
    resolved_text_class("font-semibold")
  end

  sig { returns(String) }
  def tree_link_css_class
    resolved_text_class("")
  end

  # Pre-computed label/variant pairs for Shared::StatusBadgeRowComponent, for
  # the scene tree row: always a status badge (Active/Resolved), plus Private
  # when set. The presenter picks the symbolic Ui::BadgeComponent variant so
  # the component never inspects the model directly.
  sig { returns(T::Array[Shared::StatusBadgeRowComponent::Badge]) }
  def tree_status_badges
    badges = T.let(
      [ { label: @model.status_label, variant: resolved_status_variant } ],
      T::Array[Shared::StatusBadgeRowComponent::Badge]
    )
    badges << { label: "Private", variant: :yellow } if @model.model.private?
    badges
  end

  sig { returns(String) }
  def formatted_created_at
    @model.formatted_created_at
  end

  private

  # The one branch on the wrapped scene's resolved state, memoized so
  # tree_row_css_class/tree_link_css_class/tree_status_badges each read a
  # plain value rather than re-testing resolved? themselves.
  sig { returns(T::Boolean) }
  def resolved
    @resolved ||= T.let(@model.resolved?, T.nilable(T::Boolean))
  end

  sig { params(active_class: String).returns(String) }
  def resolved_text_class(active_class)
    resolved ? "text-slate-500" : active_class
  end

  sig { returns(Symbol) }
  def resolved_status_variant
    resolved ? :gray : :green
  end
end
