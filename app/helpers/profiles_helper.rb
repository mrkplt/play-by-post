# typed: true

module ProfilesHelper
  extend T::Sig

  # The RSS feed scopes (account-level + one per non-banned game) for the current
  # user, as view-model rows. Kept out of the controller so it isn't a public-
  # action instance variable.
  sig { params(user: User).returns(T::Array[UserPresenter::RssScope]) }
  def profile_rss_scopes(user)
    UserPresenter.new(user).rss_scopes
  end

  # Absolute /feeds URL carrying the scope's token, or nil when the scope has no
  # token yet (the row then shows a Generate button instead of a feed field).
  sig { params(token: T.nilable(RssToken)).returns(T.nilable(String)) }
  def rss_feed_url(token)
    return nil unless token

    T.unsafe(self).feeds_url(token: token.token)
  end

  # Form params for an RSS scope action: a game_id for a game scope, empty for
  # the account-level scope.
  sig { params(game: T.nilable(Game)).returns(T::Hash[Symbol, T.untyped]) }
  def rss_scope_param(game)
    return {} unless game

    { game_id: game.id }
  end
end
