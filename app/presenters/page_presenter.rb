# typed: strict

# View model for a game page (detail, form, and list-row screens). Both
# capabilities are asked of policies supplied at construction rather than
# looked up in the view, so a capability rename is chased through one
# construction point instead of every page template:
#
#   options[:game_policy] — may the viewer administer the game (the game-nav's
#                           GM-only affordances, present on every page screen)
#   options[:page_policy] — may the viewer edit/delete this page
class PagePresenter < BasePresenter
  extend T::Sig

  # The viewer may administer the game this page belongs to — the flag behind
  # the game-nav's GM-only affordances on every page screen.
  sig { returns(T::Boolean) }
  def can_manage_game?
    @options.fetch(:game_policy).manage?
  end

  # The viewer may edit/delete this page — Shared::PageDetailComponent's
  # GM-only affordances.
  sig { returns(T::Boolean) }
  def can_manage?
    @options.fetch(:page_policy).manage?
  end

  sig { returns(Game) }
  def game
    @model.game
  end

  sig { returns(String) }
  def title
    @model.title.to_s
  end

  sig { returns(String) }
  def body
    @model.body.to_s
  end

  sig { returns(T::Boolean) }
  def body?
    @model.body.present?
  end

  sig { returns(T::Boolean) }
  def new_record? = @model.new_record?

  sig { returns(T.nilable(String)) }
  def slug = @model.slug

  sig { returns(T.nilable(Integer)) }
  def id = @model.id

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end
end
