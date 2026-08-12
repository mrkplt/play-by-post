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
end
