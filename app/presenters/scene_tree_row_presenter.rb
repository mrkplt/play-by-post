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

  sig { returns(String) }
  def title
    @model.title
  end

  sig { returns(String) }
  def tree_row_css_class
    @model.resolved? ? "text-slate-500" : "font-semibold"
  end

  sig { returns(String) }
  def tree_link_css_class
    @model.resolved? ? "text-slate-500" : ""
  end

  # Pre-computed label/variant pairs for Shared::StatusBadgeRowComponent, for
  # the scene tree row: always a status badge (Active/Resolved), plus Private
  # when set. The presenter picks the symbolic Ui::BadgeComponent variant so
  # the component never inspects the model directly.
  sig { returns(T::Array[Shared::StatusBadgeRowComponent::Badge]) }
  def tree_status_badges
    badges = T.let(
      [ { label: @model.status_label, variant: @model.resolved? ? :gray : :green } ],
      T::Array[Shared::StatusBadgeRowComponent::Badge]
    )
    badges << { label: "Private", variant: :yellow } if @model.model.private?
    badges
  end

  sig { returns(String) }
  def formatted_created_at
    @model.formatted_created_at
  end
end
