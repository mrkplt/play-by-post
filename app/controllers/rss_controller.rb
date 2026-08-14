# typed: strict

# The campaign-log RSS feed, delivered on the machine-auth surface. The token
# (an ApiToken with scope "rss") is the sole credential and carries the game;
# there is no game id in the path. Authorization (active membership) is
# re-checked here on every request via GamePolicy#feed?, so the feed reflects
# the member's *current* standing, not the standing when the token was minted.
class RssController < DataApplicationController
  extend T::Sig

  after_action :verify_authorized, only: :feed

  sig { void }
  def feed
    token = T.must(current_api_token)
    authorize token, :feed?

    game = T.must(token.game)
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
    @summaries = T.let(
      SceneSummary.public_for_game(game).limit(20).map { |s| SceneSummaryPresenter.new(s, game: game, urls: self) },
      T.nilable(T::Array[SceneSummaryPresenter])
    )
    render :feed, formats: :rss, layout: false
  end
end
