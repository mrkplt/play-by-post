# typed: strict

# View model for a game page, across every screen it appears on: the detail
# and form screens, and the row in the Pages list.
#
# Collaborators are supplied at construction rather than reached for, so a
# capability rename or a route change is chased through one construction point
# instead of every page template:
#
#   options[:game_policy] — may the viewer administer the game (the game-nav's
#                           GM-only affordances, present on every page screen)
#   options[:page_policy] — may the viewer edit/delete this page
#   options[:game]/[:urls] — the game and the constructing controller, used to
#                           resolve this page's own href for the list row and
#                           the form screens' Cancel target
class PagePresenter < BasePresenter
  extend T::Sig
  include Draftable::Presentation

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

  # This page's own URL, resolved here so the Pages list renders a finished
  # href rather than calling a route helper in the template.
  sig { returns(String) }
  def href
    @options.fetch(:urls).game_page_path(@options.fetch(:game), @model)
  end

  # The page's draft/publish route endpoints, split into their own presenter to
  # keep this class under the method ceiling (see PageRoutesPresenter).
  sig { returns(PageRoutesPresenter) }
  def routes
    PageRoutesPresenter.new(@model, game: @options.fetch(:game), urls: @options.fetch(:urls))
  end

  # Where Cancel returns to on the form screens: an unsaved page has no show
  # URL yet, so it goes back to the game's Pages tab; an existing page returns
  # to its own detail screen (#href).
  sig { returns(String) }
  def cancel_href
    return @options.fetch(:urls).game_path(@options.fetch(:game), anchor: "pages") if new_record?

    href
  end

  # This page's own title/href, pre-paired for the Pages list row — the two
  # values Shared::GamePagesListComponent needs about the page itself, before
  # it adds the row's GM-only controls.
  sig { returns({ title: String, href: String }) }
  def list_row_attributes
    { title: title, href: href }
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
