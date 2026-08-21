# typed: strict

# View model for the campaign-log listing: a page of scene summaries plus its
# Pagy state. Wraps the paginated collection so the index component asks
# "how many / empty state / the entries themselves" of one presenter, instead
# of holding a raw array of models and a bare Pagy object to interrogate.
# The game, url_helpers and policy needed to build each entry's paths are
# supplied at construction and threaded through to every SceneSummaryPresenter
# this hands back, so a summary entry never builds its own paths either.
class SceneSummaryCollectionPresenter < BasePresenter
  extend T::Sig

  sig { returns(T::Boolean) }
  def empty?
    @model.empty?
  end

  # Each summary in the current page, wrapped with the same game/url_helpers
  # every SceneSummaryPresenter needs to resolve its scene's path.
  sig { returns(T::Array[SceneSummaryPresenter]) }
  def entries
    @model.map do |summary|
      SceneSummaryPresenter.new(
        summary, game: @options.fetch(:game), urls: @options.fetch(:urls), viewer: @options.fetch(:viewer, nil)
      )
    end
  end

  # Pagy's own series-nav markup — Pagy is a plain object (not an
  # ActiveRecord model), so handing it through is not a layering violation;
  # this method exists so the component never touches @options[:pagy] itself.
  sig { returns(String) }
  def pagy_nav
    @options.fetch(:pagy).series_nav
  end
end
