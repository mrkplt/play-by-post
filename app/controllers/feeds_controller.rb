# typed: true

# Scoped RSS feed endpoint. The token is an identity credential: it is reverse-
# looked-up to its owning user and game, and that user becomes the authorization
# actor (pundit_user). The game is then authorized through GamePolicy#show? like
# any other action — so a token whose owner has been removed or banned from the
# game stops working, because show? re-checks membership.
class FeedsController < ApplicationController
  extend T::Sig

  skip_before_action :authenticate_user!, only: [ :show ]
  after_action :verify_authorized
  # A feed reader needs a status code, not an HTML redirect: a policy denial on
  # this endpoint is a 401, not the app-wide redirect_back.
  rescue_from Pundit::NotAuthorizedError, with: :deny_feed

  sig { void }
  def show
    rss_token = RssToken.find_by(token: params[:token])
    return unauthorized_feed unless rss_token

    @feed_user = T.let(rss_token.user, T.nilable(User))
    @game = T.let(rss_token.game, T.nilable(Game))
    authorize T.must(@game), :show?

    @summaries = summaries_for(T.must(@game))
    render layout: false
  end

  private

  # Pundit authorizes as the token's owner rather than the (absent) session user.
  sig { returns(T.nilable(User)) }
  def pundit_user
    @feed_user
  end

  sig { params(game: Game).returns(ActiveRecord::Relation) }
  def summaries_for(game)
    SceneSummary
      .joins(:scene)
      .where(scenes: { game_id: game.id, private: false })
      .where.not(scenes: { resolved_at: nil })
      .includes(:scene)
      .order("scenes.resolved_at DESC")
      .limit(50)
  end

  sig { void }
  def unauthorized_feed
    skip_authorization
    head :unauthorized
  end

  sig { params(_error: Pundit::NotAuthorizedError).void }
  def deny_feed(_error)
    head :unauthorized
  end
end
