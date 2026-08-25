# typed: strict

# View model for the profile's "Your Games" section: one GameControlRowPresenter
# per profile-listing membership, with the viewer's rss/api tokens and key
# authorizations each indexed ONCE so the rows do no per-game queries. Replaces
# the three feature-first collection builders (the feed-rows loop,
# ApiTokensPresenter, and KeyContributionsPresenter) with a single game-first
# one. A presenter composing presenters — parallels SceneSummaryCollectionPresenter.
class GameControlsPresenter < BasePresenter
  extend T::Sig

  sig { returns(T::Array[GameControlRowPresenter]) }
  def rows
    @model.filter_map do |membership|
      game = membership.game
      next unless game

      game_id = game.id
      GameControlRowPresenter.new(
        game,
        feed_token: tokens_for("rss")[game_id],
        api_token: tokens_for("api")[game_id],
        contributed_features: contributed_for(game_id),
        urls: @options.fetch(:urls)
      )
    end
  end

  private

  sig { params(scope: String).returns(T::Hash[Integer, ApiToken]) }
  def tokens_for(scope)
    tokens_by_scope.fetch(scope, {})
  end

  sig { returns(T::Hash[String, T::Hash[Integer, ApiToken]]) }
  def tokens_by_scope
    @tokens_by_scope ||= T.let(
      @options.fetch(:user).api_tokens
        .group_by(&:scope)
        .transform_values { |tokens| tokens.index_by(&:game_id) },
      T.nilable(T::Hash[String, T::Hash[Integer, ApiToken]])
    )
  end

  sig { returns(T::Hash[Integer, T::Array[GameKeyAuthorization]]) }
  def features_by_game
    @features_by_game ||= T.let(
      @options.fetch(:user).game_key_authorizations.group_by(&:game_id),
      T.nilable(T::Hash[Integer, T::Array[GameKeyAuthorization]])
    )
  end

  sig { params(game_id: Integer).returns(T::Set[String]) }
  def contributed_for(game_id)
    (features_by_game[game_id] || []).map(&:feature).to_set
  end
end
