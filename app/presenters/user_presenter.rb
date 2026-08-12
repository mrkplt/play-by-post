# typed: strict

class UserPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def display_name_or_email
    @model.display_name || @model.email.split("@").first
  end

  sig { params(limit: T.nilable(Integer)).returns(ActiveRecord::Relation) }
  def games_by_recent_activity(limit: nil)
    query = @model.games
      .where.not("game_members.status" => [ "removed", "banned" ])
      .left_joins(:scenes)
      .select("games.id, games.name, games.created_at, MAX(scenes.updated_at) as latest_activity")
      .group("games.id", "games.name", "games.created_at")
      .order(Arel.sql("COALESCE(MAX(scenes.updated_at), games.created_at) DESC"))

    query = query.limit(limit) if limit
    query
  end

  # Games the nav drawer lists: every membership except banned (banned games
  # disappear entirely), each paired with its membership so the drawer can pick
  # the right status icon (GM crown / former moon / plain). Ordered by name.
  # Soft-deleted games are dropped (Game.all carries the default scope) — their
  # membership survives but has no visible game.
  sig { returns(T::Array[GameMember]) }
  def drawer_memberships
    @model.game_members
      .where.not(status: "banned")
      .where(game_id: Game.all)
      .includes(:game)
      .sort_by { |m| m.game&.name.to_s }
  end

  # One RSS-feed scope per row for the profile page: one per non-banned game,
  # each paired with its existing token if any and a `last` flag so the view
  # needs no index arithmetic. The view turns these into feed URLs and form
  # params.
  RssScope = Struct.new(:label, :game, :token, :last, keyword_init: true)

  sig { returns(T::Array[RssScope]) }
  def rss_scopes
    tokens_by_game = @model.rss_tokens.index_by(&:game_id)

    scopes = drawer_memberships.map do |membership|
      game = T.must(membership.game)
      RssScope.new(label: game.name, game: game, token: tokens_by_game[game.id], last: false)
    end

    T.must(scopes.last).last = true unless scopes.empty?
    scopes
  end
end
