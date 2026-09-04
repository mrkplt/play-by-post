# typed: strict

# A page's viewer-capability predicates, split out of PagePresenter to keep that
# class under the project's method ceiling — the same reason PageRoutesPresenter
# exists. Both policies are injected, never built here (view-layering R2):
#
#   #can_manage_game? — may administer the owning game (game-nav GM affordances)
#   #can_manage?      — the detail screen's edit/delete affordance (page GM-only)
#   #can_edit?        — the per-row Edit affordance (GM-only; policy #update?)
#   #can_delete?      — the per-row Delete affordance (GM or the page's own
#                       author while contributions are on; policy #destroy?,
#                       Fizzy #18) — so a row can show Delete to an owner
#                       without also showing Edit.
class PageActionsPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Page, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  def can_manage_game?
    @options.fetch(:game_policy).manage?
  end

  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:page_policy).manage?
  end

  sig { returns(T::Boolean) }
  def can_edit?
    @options.fetch(:page_policy).update?
  end

  sig { returns(T::Boolean) }
  def can_delete?
    @options.fetch(:page_policy).destroy?
  end
end
