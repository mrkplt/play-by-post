# typed: true

# Scoped RSS feed endpoint. The token is the sole input: its scope is resolved by
# reverse lookup. An account-level token (game_id nil) aggregates scene summaries
# across every game the owner is an active member of; a game-level token renders
# just that game. Membership is re-checked at request time so a removed member's
# live token stops working.
class FeedsController < ApplicationController
  extend T::Sig

  skip_before_action :authenticate_user!, only: [ :show ]
  # show is public and token-gated (its own RSS-token access rules); no policy.
  after_action :verify_authorized, except: :show

  sig { void }
  def show
    rss_token = RssToken.find_by(token: params[:token])
    return head(:unauthorized) unless rss_token

    @games = accessible_games(rss_token)
    return head(:unauthorized) if @games.empty?

    @account_level = rss_token.game_id.nil?
    @summaries = summaries_for(@games)
    render layout: false
  end

  private

  sig { params(rss_token: RssToken).returns(T::Array[Game]) }
  def accessible_games(rss_token)
    member_games = Game.where(
      id: GameMember.where(user_id: rss_token.user_id, status: "active").select(:game_id)
    )
    member_games = member_games.where(id: rss_token.game_id) if rss_token.game_id
    member_games.order(:name).to_a
  end

  sig { params(games: T::Array[Game]).returns(ActiveRecord::Relation) }
  def summaries_for(games)
    SceneSummary
      .joins(scene: :game)
      .where(scenes: { game_id: games.map(&:id), private: false })
      .where.not(scenes: { resolved_at: nil })
      .includes(scene: :game)
      .order("scenes.resolved_at DESC")
      .limit(50)
  end
end
