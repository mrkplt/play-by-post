# typed: strict

# Assembles the profile's "API tokens" rows for one person: one
# ApiTokenRowPresenter per non-banned game membership, paired with that user's
# api-scoped token for the game (if any). The tokens are indexed ONCE so the
# rows do no per-game query. Mirrors KeyContributionRowsBuilder.
class ApiTokenRowsBuilder
  extend T::Sig

  sig { params(user: User, urls: T.untyped).void }
  def initialize(user:, urls:)
    @user = user
    @urls = urls
  end

  sig { returns(T::Array[ApiTokenRowPresenter]) }
  def rows
    memberships.filter_map do |membership|
      game = membership.game
      next unless game

      ApiTokenRowPresenter.new(game, token: tokens_by_game_id[game.id], urls: @urls)
    end
  end

  private

  sig { returns(T::Hash[Integer, ApiToken]) }
  def tokens_by_game_id
    @tokens_by_game_id ||= T.let(@user.api_tokens.where(scope: "api").index_by(&:game_id), T.nilable(T::Hash[Integer, ApiToken]))
  end

  sig { returns(ActiveRecord::Relation) }
  def memberships
    @user.game_members.where.not(status: "banned").includes(:game).order("games.name")
  end
end
