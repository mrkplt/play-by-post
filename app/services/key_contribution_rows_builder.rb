# typed: strict

# Assembles the profile's "fund AI for your games" rows for one person: one
# KeyContributionRowPresenter per game they belong to (non-banned), each told
# which features their key already funds there. The authorizations are loaded
# and grouped ONCE so the rows do no per-game query.
class KeyContributionRowsBuilder
  extend T::Sig

  sig { params(user: User, urls: T.untyped).void }
  def initialize(user:, urls:)
    @user = user
    @urls = urls
  end

  sig { returns(T::Array[KeyContributionRowPresenter]) }
  def rows
    memberships.filter_map do |membership|
      game = membership.game
      next unless game

      KeyContributionRowPresenter.new(game, contributed_features: contributed_for(game.id), urls: @urls)
    end
  end

  private

  # Non-banned memberships, game preloaded, ordered by game name — the same
  # surface UserPresenter#feed_memberships exposes for the other profile lists.
  sig { returns(ActiveRecord::Relation) }
  def memberships
    @user.game_members.where.not(status: "banned").includes(:game).order("games.name")
  end

  sig { returns(T::Hash[Integer, T::Array[GameKeyAuthorization]]) }
  def features_by_game
    @features_by_game ||= T.let(@user.game_key_authorizations.group_by(&:game_id), T.nilable(T::Hash[Integer, T::Array[GameKeyAuthorization]]))
  end

  sig { params(game_id: Integer).returns(T::Set[String]) }
  def contributed_for(game_id)
    (features_by_game[game_id] || []).map(&:feature).to_set
  end
end
