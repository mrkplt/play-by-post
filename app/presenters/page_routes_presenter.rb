# typed: strict

# The draft/publish endpoints for a page, split out of PagePresenter to keep
# that class under the project's method ceiling: route resolution is a distinct
# concern from the page's own display values. Wraps the Page model directly and
# takes the constructing controller as `urls:` plus the owning `game:`,
# mirroring SceneRoutesPresenter.
class PageRoutesPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Page, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The editor's draft autosave endpoint (Pages::DraftsController#save).
  sig { returns(String) }
  def save_draft_path
    urls.save_draft_game_page_path(game, @model)
  end

  # The Publish affordance's target (Pages::DraftsController#publish).
  sig { returns(String) }
  def publish_path
    urls.publish_game_page_path(game, @model)
  end

  private

  sig { returns(T.untyped) }
  def urls
    @options.fetch(:urls)
  end

  sig { returns(Game) }
  def game
    @options.fetch(:game)
  end
end
