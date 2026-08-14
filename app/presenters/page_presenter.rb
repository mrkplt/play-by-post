# typed: strict

# View model for a single game page screen. The game-nav "can manage" flag
# and the page's own manage capability are asked of policies supplied at
# construction (options[:game_policy] / options[:page_policy]) rather than
# looked up in the view, so a capability rename is chased through one
# construction point instead of every page template.
class PagePresenter < BasePresenter
  extend T::Sig

  # The viewer may administer the game this page belongs to — the flag behind
  # the game-nav's GM-only affordances on every page screen.
  sig { returns(T::Boolean) }
  def can_manage_game?
    @options.fetch(:game_policy).manage?
  end

  # The viewer may edit/delete this page — the Shared::PageDetailComponent's
  # GM-only affordances.
  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:page_policy).manage?
  end
end
