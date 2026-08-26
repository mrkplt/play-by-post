# typed: strict

# View model for one game's card in the profile's "Your Games" control-plane
# section: the game name plus the per-credential row presenters (feed/api) and
# the AI-funding cells, so Shared::GameControlsComponent reads one object per
# game instead of three parallel section arrays. The sub-presenters are the
# same ones the old feature-first sections rendered — this row only regroups
# them game-first.
class GameControlRowPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Game, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def name
    @model.name
  end

  sig { returns(GameFeedRowPresenter) }
  def feed
    @feed ||= T.let(
      GameFeedRowPresenter.new(@model, token: @options[:feed_token], urls: urls),
      T.nilable(GameFeedRowPresenter)
    )
  end

  sig { returns(ApiTokenRowPresenter) }
  def api
    @api ||= T.let(
      ApiTokenRowPresenter.new(@model, token: @options[:api_token], urls: urls),
      T.nilable(ApiTokenRowPresenter)
    )
  end

  sig { returns(T::Array[Shared::GameControlsComponent::Cell]) }
  def ai_cells
    KeyContributionRowPresenter
      .new(@model, contributed_features: @options.fetch(:contributed_features), urls: urls)
      .cells
  end

  private

  sig { returns(T.untyped) }
  def urls
    @options.fetch(:urls)
  end
end
