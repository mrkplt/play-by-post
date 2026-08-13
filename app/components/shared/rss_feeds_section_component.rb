# typed: strict

# The profile's "RSS Feeds" section: one row per game the user belongs to, each
# offering to create a feed token or — when one exists — showing the copyable
# feed URL (via Ui::SecretFieldComponent) and a revoke control. Owns the
# per-game branching so the profile template stays logic-free; takes the
# memberships and a token lookup, not raw query results to iterate in ERB.
class Shared::RssFeedsSectionComponent < ApplicationComponent
  extend T::Sig

  # A single game's feed row, resolved to presentation-ready values.
  class Row < T::Struct
    const :game_id, Integer
    const :game_name, String
    const :token, T.nilable(ApiToken)
  end

  sig do
    params(
      memberships: T::Enumerable[GameMember],
      tokens_by_game_id: T::Hash[Integer, ApiToken]
    ).void
  end
  def initialize(memberships:, tokens_by_game_id:)
    @rows = T.let(build_rows(memberships, tokens_by_game_id), T::Array[Row])
  end

  sig { returns(T::Array[Row]) }
  attr_reader :rows

  sig { returns(T::Boolean) }
  def any_games?
    @rows.any?
  end

  sig { params(row: Row, index: Integer).returns(T::Boolean) }
  def last_row?(row, index)
    index == @rows.length - 1
  end

  sig { params(token: ApiToken).returns(String) }
  def feed_url(token)
    T.unsafe(helpers).rss_feed_url(token: token.token)
  end

  private

  sig do
    params(
      memberships: T::Enumerable[GameMember],
      tokens_by_game_id: T::Hash[Integer, ApiToken]
    ).returns(T::Array[Row])
  end
  def build_rows(memberships, tokens_by_game_id)
    memberships.map do |membership|
      game = T.must(membership.game)
      Row.new(game_id: game.id, game_name: game.name, token: tokens_by_game_id[game.id])
    end
  end
end
