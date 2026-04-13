# typed: strict

class UserPresenter < BasePresenter
  extend T::Sig

  sig { returns(String) }
  def display_name_or_email
    @model.display_name || @model.email.split("@").first
  end

  sig { params(limit: T.nilable(Integer)).returns(ActiveRecord::Relation) }
  def games_by_recent_activity(limit: nil)
    query = games
      .where.not("game_members.status" => [ "removed", "banned" ])
      .left_joins(:scenes)
      .select("games.id, games.name, games.created_at, MAX(scenes.updated_at) as latest_activity")
      .group("games.id", "games.name", "games.created_at")
      .order(Arel.sql("COALESCE(MAX(scenes.updated_at), games.created_at) DESC"))

    query = query.limit(limit) if limit
    query
  end
end
